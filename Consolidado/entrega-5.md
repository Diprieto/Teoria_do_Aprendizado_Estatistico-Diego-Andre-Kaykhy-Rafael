# Entrega 5 — Regressão Logística Binária

**Notebook:** `Logistica.ipynb` · **Linguagem:** R

---

## Objetivo

Mudar o tipo de problema: em vez de prever *quanto* se movimenta, prever *qual categoria* de operação. A pergunta passa a ser — dado o peso da carga e o tipo de navegação, é possível classificar um registro como embarque ou desembarque?

---

## 1. Leitura e tratamento

```r
suppressPackageStartupMessages(library(dplyr))

exportacao_cargas <- readRDS("/content/exportacao_cargas.rds")

dados_modelo <- exportacao_cargas %>%
  mutate(
    # Binarizar SENTIDO: 1 = DESEMBARQUE, 0 = EMBARQUE
    y_sentido = as.integer(SENTIDO == "DESEMBARQUE"),

    # Corrigir vírgula para ponto e converter para numérico
    TOTAL_TONELADAS = as.numeric(gsub(",", ".", TOTAL_TONELADAS)),

    # Converter colunas categóricas em fatores
    TIPO_NAVEGACAO = as.factor(TIPO_NAVEGACAO),
    NATUREZA_CARGA = as.factor(NATUREZA_CARGA)
  ) %>%
  filter(!is.na(y_sentido), !is.na(TOTAL_TONELADAS))
```

Três operações essenciais:

**Binarização.** `as.integer(SENTIDO == "DESEMBARQUE")` gera 1 para desembarque e 0 para embarque. A comparação lógica devolve `TRUE`/`FALSE`, e o `as.integer` converte em 1/0 — formato exigido pelo `glm` binomial.

**Conversão numérica.** O mesmo `gsub` das outras entregas, resolvendo a vírgula decimal.

**Fatores.** `as.factor()` avisa o R de que a variável é categórica, para que ele crie as dummies em vez de tratar os rótulos como números.

O `filter` no fim remove os `NA` das variáveis do modelo — sem isso, o `glm` descartaria essas linhas silenciosamente e o número de observações não bateria com o esperado.

---

## 2. Distribuição da variável-resposta

```r
cat("\n--- Distribuição da Variável Resposta (y_sentido) ---\n")
print(table(dados_modelo$y_sentido))
print(prop.table(table(dados_modelo$y_sentido)))
```

```
     0      1
574347 522667

        0         1
0.5235548 0.4764452
```

| Classe | Contagem | Proporção |
|---|---|---|
| 0 — Embarque | 574.347 | 52,36% |
| 1 — Desembarque | 522.667 | 47,64% |

**A base está bem equilibrada.** Isso é positivo — não há necessidade de reamostragem ou ponderação de classes. Mas guarde o número **52,36%**: ele é a *taxa base*, o acerto que qualquer classificador trivial obteria chutando sempre a classe majoritária. Todo desempenho do modelo precisa ser comparado contra esse piso.

---

## 3. Ajuste do modelo logístico

```r
modelo_logistico <- glm(
  y_sentido ~ TOTAL_TONELADAS + TIPO_NAVEGACAO,
  family = binomial(link = "logit"),
  data = dados_modelo
)

summary(modelo_logistico)
```

O `family = binomial(link = "logit")` é o que distingue a regressão logística da linear: em vez de modelar a média diretamente, modela o **log das chances** (log-odds), garantindo que a previsão fique sempre entre 0 e 1.

### Resultados

```
Coefficients:
                            Estimate Std. Error z value Pr(>|z|)
(Intercept)               -1.782e-01  4.934e-03  -36.13   <2e-16 ***
TOTAL_TONELADAS           -3.369e-05  3.238e-07 -104.02   <2e-16 ***
TIPO_NAVEGACAOLONGO CURSO  1.848e-01  5.336e-03   34.63   <2e-16 ***

    Null deviance: 1518349  on 1097013  degrees of freedom
Residual deviance: 1502542  on 1097011  degrees of freedom
AIC: 1502548

Number of Fisher Scoring iterations: 4
```

A queda da deviance é pequena: de 1.518.349 para 1.502.542, cerca de **1%**. Sinal de que o modelo agrega pouca informação sobre o chute trivial.

---

## 4. Razões de chance (Odds Ratios)

```r
razoes_chance <- exp(coef(modelo_logistico))
print(round(razoes_chance, 4))
```

```
              (Intercept)           TOTAL_TONELADAS TIPO_NAVEGACAOLONGO CURSO
                   0.8367                    1.0000                    1.2030
```

Os coeficientes do `glm` vêm na escala logit, que não é interpretável diretamente. O `exp()` os converte em razões de chance, onde 1,0 significa "nenhum efeito".

### Tipo de navegação

**OR = 1,2030** → cargas de **longo curso têm 20,3% mais chance de ser desembarque** do que cargas de cabotagem.

Faz sentido operacional: longo curso envolve comércio internacional, e o porto analisado recebe volume importado relevante.

### Total de toneladas

**Coeficiente = −3,369e−05** (negativo). O OR por tonelada arredonda para 1,0000, mas o efeito não é nulo — ele é pequeno *por unidade* e se acumula em volumes grandes:

```
exp(-3,369e-05 × 10.000) = exp(-0,3369) ≈ 0,714
```

**A cada 10.000 toneladas adicionais, a chance de ser desembarque cai cerca de 28,6%.** Ou seja, cargas mais pesadas tendem a ser **embarques** — coerente com um porto exportador de granel, onde os maiores volumes saem, não entram.

> Atenção ao sinal: por ser negativo, o coeficiente indica redução da chance de desembarque. Descrever o efeito como "aumento" inverteria a conclusão.

---

## 5. Matrizes de confusão em três limiares

```r
dados_modelo$prob_predita <- predict(modelo_logistico, type = "response")

for (limiar in c(0.3, 0.5, 0.7)) {
  pred_classe <- as.integer(dados_modelo$prob_predita > limiar)
  cat(paste0("\n--- Matriz de Confusão (Limiar c = ", limiar, ") ---\n"))
  matriz <- table(Real = dados_modelo$y_sentido, Previsto = pred_classe)
  print(matriz)

  acuracia <- mean(pred_classe == dados_modelo$y_sentido)
  cat("Acurácia:", round(acuracia, 4), "\n")
}
```

O `type = "response"` devolve a probabilidade prevista (0 a 1) em vez do logit. O limiar é o corte que transforma essa probabilidade em decisão binária.

### c = 0,3 — limiar permissivo

```
    Previsto
Real      0      1
   0  21489 552858
   1   5541 517126
Acurácia: 0.4910
```

Classifica quase tudo como desembarque. Gera **552.858 falsos positivos** contra apenas 5.541 falsos negativos — uma proporção de 100 para 1. Acurácia de 49,1%, **abaixo do chute trivial**.

### c = 0,5 — ponto de equilíbrio

```
    Previsto
Real      0      1
   0 354144 220203
   1 272509 250158
Acurácia: 0.5509
```

Melhor desempenho dos três: **55,09%**. É o único limiar que supera a taxa base de 52,36%, e mesmo assim por menos de 3 pontos percentuais.

### c = 0,7 — limiar rígido

```
    Previsto
Real      0
   0 574347
   1 522667
Acurácia: 0.5236
```

A coluna do previsto = 1 **desapareceu**: nenhuma probabilidade prevista ultrapassa 0,7, e o modelo classifica 100% dos casos como embarque. A acurácia de 52,36% é exatamente a proporção da classe majoritária — prova aritmética de que, nesse ponto, o modelo deixou de discriminar.

### Resumo comparativo

| Limiar | Acurácia | vs. taxa base (52,36%) | Comportamento |
|---|---|---|---|
| 0,3 | 49,10% | −3,3 p.p. | Quase tudo vira desembarque |
| **0,5** | **55,09%** | **+2,7 p.p.** | Único com ganho real |
| 0,7 | 52,36% | 0,0 p.p. | Colapsa na classe majoritária |

---

## 6. Área sob a curva ROC (AUC)

```r
set.seed(42)
amostra_auc <- dados_modelo %>% sample_n(min(50000, nrow(dados_modelo)))

p_pos <- amostra_auc$prob_predita[amostra_auc$y_sentido == 1]
p_neg <- amostra_auc$prob_predita[amostra_auc$y_sentido == 0]

auc <- mean(outer(p_pos, p_neg, ">"))
cat("AUC (Área sob a Curva ROC - Amostra 50k):", round(auc, 4), "\n")
```

O cálculo usa a definição probabilística da AUC: a chance de um caso positivo sorteado ao acaso receber probabilidade maior que um caso negativo sorteado ao acaso. O `outer(p_pos, p_neg, ">")` compara todos os pares e a média das comparações verdadeiras é a AUC.

A amostragem de 50 mil linhas é necessária por memória — na base completa, a matriz de comparações teria mais de 300 bilhões de elementos e estouraria a RAM do Colab. O `set.seed(42)` garante que a amostra seja sempre a mesma.

> **Pendência:** o valor da AUC não consta na saída salva do notebook. É a métrica mais informativa aqui, porque independe da escolha de limiar — vale reexecutar e registrar. Referência para leitura: 0,5 significa aleatório, 0,7 é aceitável, acima de 0,8 é bom.

---

## 7. Custo dos erros

O notebook argumenta que o **falso positivo custa mais que o falso negativo**: prever desembarque onde havia embarque gera desorganização e realocação desnecessária de carga no terminal.

O raciocínio é razoável em termos operacionais, e o limiar 0,3 de fato produz 100 vezes mais falsos positivos que falsos negativos. Vale observar, porém, que essa conclusão aponta para escolher um limiar **mais alto**, e não mais baixo — o corte permissivo é justamente o que multiplica o erro mais caro.

---

## Pontos de atenção

- **Poder preditivo fraco.** O melhor resultado (55,09%) supera o chute trivial em menos de 3 pontos percentuais. Com apenas duas variáveis, o modelo captura pouco do que determina o sentido da operação.
- **Variáveis não aproveitadas.** `NATUREZA_CARGA` é convertida em fator no tratamento, mas **nunca entra na fórmula do `glm`**. Dado o peso enorme dessa variável na Entrega 4, incluí-la é o caminho mais direto para melhorar o modelo. `MERCADORIAS` e `TERMINAIS` também deveriam ajudar.
- **Avaliação na própria base de treino.** As matrizes de confusão usam os mesmos dados do ajuste, então a acurácia é otimista. As entregas 6 e 7 corrigem essa limitação com holdout e validação cruzada.
- **Divergências de digitação no relatório.** O texto registra "20,3$" (por 20,3%) e acurácia de 49,71% em c = 0,3, enquanto a saída mostra 49,10%.

---

## Conclusão

O modelo identifica duas relações estatisticamente sólidas e operacionalmente coerentes: longo curso puxa para desembarque (+20,3% de chance) e cargas pesadas puxam para embarque (−28,6% a cada 10 mil toneladas).

O poder de classificação, no entanto, é limitado. A comparação entre os três limiares é didática justamente por mostrar que a acurácia sozinha engana: em c = 0,7 o modelo atinge 52,36% sem classificar corretamente um único desembarque. Acrescentar `NATUREZA_CARGA` ao modelo e registrar a AUC são os próximos passos naturais.
