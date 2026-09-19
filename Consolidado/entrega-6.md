# Entrega 6 — Validação Holdout (Treino 70% / Teste 30%)

**Notebook:** `Aula6PI.ipynb` · **Linguagem:** R

---

## Objetivo

Mudar a pergunta. Até aqui o critério era "o modelo se ajusta bem aos dados?" — medido pelo R². Agora a pergunta é **"o modelo generaliza para dados que nunca viu?"**, o que exige separar uma parte da base e mantê-la intocada durante o ajuste.

---

## 1. Leitura e limpeza

```r
if(!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)

dados <- readRDS("/content/exportacao_cargas.rds")

# Conversão de texto para número (vírgula → ponto)
dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", dados$TOTAL_TONELADAS))
dados$TOTAL_TEU       <- as.numeric(gsub(",", ".", dados$TOTAL_TEU))

# Remover linhas vazias
dados_limpos <- subset(dados, !is.na(TOTAL_TONELADAS) &
                              !is.na(TOTAL_TEU) &
                              !is.na(SENTIDO) &
                              !is.na(TIPO_NAVEGACAO))
```

O `subset` filtra `NA` nas quatro variáveis que entram nos modelos. Esse passo precisa vir **antes** da divisão: se treino e teste tiverem proporções diferentes de dados faltantes, a comparação fica contaminada.

---

## 2. Divisão 70/30 — antes de qualquer ajuste

```r
set.seed(1)
n_linhas <- nrow(dados_limpos)
itr <- sample(n_linhas, round(0.7 * n_linhas))

tr <- dados_limpos[itr, ]    # Base de Treino (70%)
te <- dados_limpos[-itr, ]   # Base de Teste (30%)
```

**A ordem é o ponto central desta entrega.** Dividir antes de ajustar é o que impede o *vazamento de informação* (data leakage): se qualquer decisão sobre o modelo — escolha de variáveis, tratamento, transformação — for tomada olhando o conjunto de teste, ele deixa de ser uma amostra "não vista" e a avaliação perde o sentido.

O `sample` sorteia 70% dos índices; a indexação negativa `[-itr, ]` pega exatamente o complemento, garantindo que nenhuma linha apareça nos dois conjuntos.

O `set.seed(1)` fixa o sorteio, tornando o resultado reproduzível.

---

## 3. Dois candidatos, ajustados só no treino

```r
m1 <- lm(TOTAL_TONELADAS ~ TOTAL_TEU, data = tr)
m2 <- lm(TOTAL_TONELADAS ~ TOTAL_TEU + SENTIDO + TIPO_NAVEGACAO, data = tr)
```

| Modelo | Fórmula | Característica |
|---|---|---|
| **m1** | `TOTAL_TONELADAS ~ TOTAL_TEU` | Simples — uma variável |
| **m2** | `TOTAL_TONELADAS ~ TOTAL_TEU + SENTIDO + TIPO_NAVEGACAO` | Múltiplo — mais flexível |

Note o `data = tr` nos dois: o conjunto de teste não participa do ajuste.

O experimento está montado para testar o **trade-off viés-variância**. O modelo mais flexível tende a ter menor viés, mas corre risco de variância alta (sobreajuste). O erro de teste é o juiz.

---

## 4. Métrica de erro

```r
mse <- function(m, d) {
  mean((d$TOTAL_TONELADAS - predict(m, d))^2, na.rm = TRUE)
}

rmse_m1_tr <- sqrt(mse(m1, tr))   # Treino M1
rmse_m1_te <- sqrt(mse(m1, te))   # Teste M1

rmse_m2_tr <- sqrt(mse(m2, tr))   # Treino M2
rmse_m2_te <- sqrt(mse(m2, te))   # Teste M2
```

O **MSE** é a média dos erros ao quadrado. A raiz quadrada devolve o **RMSE**, que tem a vantagem de estar na mesma unidade da variável-resposta — o resultado é lido diretamente em toneladas.

O cálculo é feito nos dois conjuntos de propósito: o RMSE de treino sozinho não diz nada sobre generalização, mas a **comparação entre treino e teste** é o que revela sobreajuste.

---

## 5. Resultado

```r
cat("=== RESULTADOS PARA O TRABALHO ===\n")
cat("RMSE Candidato 1 (Teste): ", round(rmse_m1_te, 2), "\n")
cat("RMSE Candidato 2 (Teste): ", round(rmse_m2_te, 2), "\n\n")

if(rmse_m1_te < rmse_m2_te) {
  cat("VENCEDOR: Candidato 1 possui o menor erro de teste.\n")
} else {
  cat("VENCEDOR: Candidato 2 possui o menor erro de teste.\n")
}
```

```
=== RESULTADOS PARA O TRABALHO ===
RMSE Candidato 1 (Teste):  8267.09
RMSE Candidato 2 (Teste):  8207.29

VENCEDOR: Candidato 2 possui o menor erro de teste.
```

| Modelo | RMSE (teste) | Diferença |
|---|---|---|
| Candidato 1 (simples) | 8.267,09 t | — |
| **Candidato 2 (múltiplo)** | **8.207,29 t** | −59,80 t (−0,72%) |

---

## 6. Gráfico comparativo

```r
dados_grafico <- data.frame(
  Modelo   = rep(c("Candidato 1\n(Simples)", "Candidato 2\n(Múltiplo)"), each = 2),
  Conjunto = rep(c("1. Treino", "2. Teste"), times = 2),
  RMSE     = c(rmse_m1_tr, rmse_m1_te, rmse_m2_tr, rmse_m2_te)
)

ggplot(dados_grafico, aes(x = Modelo, y = RMSE, fill = Conjunto)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = round(RMSE, 0)),
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("1. Treino" = "blue", "2. Teste" = "red")) +
  labs(
    title = "Avaliação de Modelos: Erro de Treino vs Teste",
    subtitle = "Comparação da capacidade de generalização",
    y = "RMSE (Toneladas)",
    x = "Modelos Ajustados",
    fill = "Base de Dados:"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top"
  )
```

Barras agrupadas, azul para treino e vermelho para teste, com os valores impressos acima de cada barra pelo `geom_text`. O `position_dodge` coloca treino e teste lado a lado em vez de empilhados, que é o arranjo que permite a comparação visual direta.

**O que procurar no gráfico:** a distância entre a barra azul e a vermelha de cada modelo. Se o erro de teste disparasse em relação ao de treino, seria sinal de sobreajuste. Como isso não acontece, o modelo mais flexível ganhou capacidade preditiva sem "decorar" a base de treino.

---

## Pontos de atenção

- **O ganho é marginal.** 59,8 toneladas em 8.200 é uma melhora de **0,72%**. A vitória do candidato 2 é real e consistente, mas afirmar que ele "capturou padrões estruturais melhores" exige a ressalva de magnitude — com uma partição diferente, a ordem poderia se inverter.
- **Uma única partição.** O resultado depende do `set.seed(1)`. Uma divisão sorteada de outro jeito daria números um pouco diferentes. É exatamente essa fragilidade que a Entrega 7 corrige, com validação cruzada em 5 dobras.
- **`TOTAL_TEU` como preditor.** A relação entre TEU e toneladas é quase física (contêineres têm peso), o que explica o desempenho. Mas o modelo só serve para carga conteinerizada — registros de granel têm TEU zero, e a Entrega 4 mostrou que é justamente o granel sólido que domina o volume.
- **Erro em nível absoluto.** RMSE de ~8.200 toneladas é alto frente à mediana da base. O modelo é penalizado pelos outliers, já detectados na Entrega 2.

---

## Conclusão

O candidato 2 vence com RMSE de 8.207 toneladas contra 8.267 do candidato 1. Mais importante que a vitória em si é o que o gráfico mostra: **o erro de teste não se descola do erro de treino**, ou seja, acrescentar `SENTIDO` e `TIPO_NAVEGACAO` reduziu o viés sem introduzir sobreajuste.

Esta entrega estabelece o método de avaliação honesta. A Entrega 7 fortalece a conclusão substituindo a partição única por validação cruzada, e acrescenta o bootstrap para medir a estabilidade dos coeficientes estimados.
