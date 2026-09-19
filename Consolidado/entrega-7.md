# Entrega 7 — Validação Cruzada e Bootstrap

**Notebook:** `Aula7PI.ipynb` · **Linguagem:** R

---

## Objetivo

Fechar o ciclo metodológico com duas técnicas de reamostragem que respondem a perguntas diferentes:

- **Validação cruzada k-fold** — qual modelo generaliza melhor, sem depender de uma única partição sorteada?
- **Bootstrap** — quanta incerteza existe em torno do coeficiente estimado?

---

## 1. Leitura e tratamento

```r
dados <- readRDS("/content/exportacao_cargas.rds")

dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", dados$TOTAL_TONELADAS))
dados$TOTAL_TEU       <- as.numeric(dados$TOTAL_TEU)
dados$TOTAL_UNID      <- as.numeric(dados$TOTAL_UNID)
```

Mesmo padrão das entregas anteriores. O `gsub` aparece apenas em `TOTAL_TONELADAS`; `TOTAL_TEU` e `TOTAL_UNID` são convertidos direto, por serem contagens inteiras sem parte decimal.

---

## 2. Validação cruzada k-fold (k = 5)

### Preparação das dobras

```r
k <- 5
d <- sample(rep(1:k, length = nrow(dados)))
```

O `rep(1:k, length = nrow(dados))` cria um vetor `1,2,3,4,5,1,2,3,4,5,...` do tamanho da base, e o `sample` embaralha essa sequência. O resultado é um rótulo de dobra atribuído aleatoriamente a cada linha, com as cinco dobras de tamanho praticamente idêntico.

### A função de validação

```r
cv <- function(formula) mean(sapply(1:k, function(j) {
    m <- lm(formula, data = dados[d != j, ])

    mean((dados$TOTAL_TONELADAS[d == j] - predict(m, dados[d == j, ]))^2, na.rm = TRUE)
}))
```

O mecanismo, em cada uma das 5 iterações:

1. `dados[d != j, ]` — treina com as **outras quatro dobras** (~80% da base)
2. `predict(m, dados[d == j, ])` — prevê sobre a **dobra excluída** (~20%), que o modelo nunca viu
3. Calcula o MSE dessa dobra

No fim, o `mean` externo tira a média dos 5 MSEs.

**Vantagem sobre o holdout da Entrega 6:** ali, 30% da base era usada para teste e 70% para treino, uma única vez. Aqui, **cada observação é usada para teste exatamente uma vez** e para treino quatro vezes. O resultado não depende da sorte de uma partição específica, o que reduz a variância da estimativa de erro.

### Comparação dos modelos

```r
resultados_cv <- c(m1 = cv(TOTAL_TONELADAS ~ TOTAL_TEU),
                   m2 = cv(TOTAL_TONELADAS ~ TOTAL_TEU + TOTAL_UNID))
print("Resultados da Validação Cruzada:")
print(resultados_cv)
```

```
[1] "Resultados da Validação Cruzada:"
      m1       m2
67625457 67418210
```

| Modelo | Fórmula | MSE médio | RMSE equivalente |
|---|---|---|---|
| m1 | `TOTAL_TONELADAS ~ TOTAL_TEU` | 67.625.457 | ~8.223 t |
| **m2** | `TOTAL_TONELADAS ~ TOTAL_TEU + TOTAL_UNID` | **67.418.210** | **~8.211 t** |

**m2 vence**, com MSE 0,31% menor.

Note que m2 é um modelo **aninhado** em m1: ele mantém `TOTAL_TEU` e acrescenta `TOTAL_UNID`. A comparação mede especificamente se a segunda variável agrega poder preditivo além do que a primeira já oferece.

> **Validação cruzada dos resultados:** os RMSEs aqui (~8.223 e ~8.211) são praticamente idênticos aos da Entrega 6 (8.267 e 8.207), obtidos por holdout com variáveis diferentes. Duas metodologias independentes chegando ao mesmo patamar de erro é um forte indicativo de que a estimativa é estável — e de que ~8.200 toneladas é o limite prático desse tipo de modelo nessa base.

---

## 3. Bootstrap do coeficiente

```r
b <- replicate(20, {
  i <- sample(nrow(dados), nrow(dados), replace = TRUE)
  coef(lm(TOTAL_TONELADAS ~ TOTAL_TEU + TOTAL_UNID, data = dados[i, ]))["TOTAL_TEU"]
})
```

O mecanismo de cada réplica:

1. `sample(nrow(dados), nrow(dados), replace = TRUE)` — sorteia índices **com reposição**, gerando uma base do mesmo tamanho onde algumas linhas aparecem repetidas e outras ficam de fora
2. Reajusta o modelo sobre essa base reamostrada
3. Guarda apenas o coeficiente de `TOTAL_TEU`

O `replace = TRUE` é o coração da técnica: sem reposição, cada amostra seria idêntica à original e não haveria variação nenhuma para medir.

A ideia por trás é simular o que aconteceria se fosse possível coletar a base várias vezes. A dispersão dos coeficientes entre as réplicas estima a incerteza da estimativa — **sem depender de nenhum pressuposto de normalidade**, que é justamente o que os diagnósticos da Entrega 4 mostraram estar violado.

### Erro padrão e intervalo de confiança

```r
resultados_boot <- c(ep = sd(b), quantile(b, c(0.025, 0.975), na.rm = TRUE))
print("Resultados do Bootstrap:")
print(resultados_boot)
```

```
[1] "Resultados do Bootstrap:"
        ep       2.5%      97.5%
0.03382383 6.49748812 6.60661652
```

| Métrica | Valor |
|---|---|
| Erro padrão | 0,0338 |
| Limite inferior (2,5%) | 6,4975 |
| Limite superior (97,5%) | 6,6066 |

O intervalo de confiança é o **método percentil**: descarta os 2,5% menores e os 2,5% maiores coeficientes obtidos nas réplicas, e usa o que sobra como faixa de 95%.

### Interpretação

**Cada TEU adicional corresponde a aproximadamente 6,5 toneladas**, com intervalo de confiança de 95% entre 6,50 e 6,61.

A amplitude do intervalo é de apenas **0,11 toneladas** — cerca de 1,7% do valor central. O coeficiente é extraordinariamente estável, o que faz sentido: TEU é uma medida física padronizada de contêiner, e a relação entre número de contêineres e peso é quase determinística. Somada a 1,1 milhão de observações, a precisão elevada era esperada.

**Contraste importante:** o coeficiente é preciso, mas o modelo é impreciso. O erro padrão de 0,034 convive com um RMSE de 8.200 toneladas. São coisas distintas — sabemos com muita confiança *qual é a inclinação da reta*, e ainda assim a reta explica pouco de cada registro individual, porque a maior parte da variação vem de fatores fora do modelo (natureza da carga, sobretudo, como mostrou a Entrega 4).

---

## Pontos de atenção

- **Apenas 20 réplicas de bootstrap.** O comentário no código menciona 2000 reamostragens, mas `replicate(20)` roda 20. Com 20 valores, os quantis de 2,5% e 97,5% são estimados a partir dos extremos da amostra e o intervalo é pouco confiável. O padrão recomendado é 1.000–2.000 réplicas. A redução provavelmente foi feita por tempo de execução, já que cada réplica reajusta um `lm` sobre 1,1 milhão de linhas — uma alternativa é reamostrar um subconjunto da base, ou usar computação paralela.
- **Descrição trocada dos modelos.** O texto do notebook diz que m1 usa `TOTAL_TEU` e m2 usa `TOTAL_UNID`. O código mostra que **m2 usa `TOTAL_TEU + TOTAL_UNID`** — é o modelo aninhado, não uma alternativa que troca uma variável pela outra.
- **Sem semente aleatória.** Nem o `sample` das dobras nem o do bootstrap têm `set.seed()`. Os números mudam a cada execução. As entregas 5 e 6 usam semente; vale padronizar aqui também.
- **Ganho pequeno.** A diferença de 0,31% entre m1 e m2 é menor que a variação esperada entre execuções diferentes das dobras. Sem semente fixa, seria prudente repetir a validação algumas vezes antes de declarar vencedor.

---

## Conclusão

A validação cruzada confirma o padrão da Entrega 6: o modelo com a variável adicional tem erro menor, mas por margem estreita. O valor de ~8.200 toneladas de RMSE se repete em duas metodologias independentes, o que sugere ser esse o teto de desempenho para modelos lineares simples nessa base.

O bootstrap mostra que o coeficiente de `TOTAL_TEU` — cerca de 6,5 toneladas por contêiner — é bastante estável, com intervalo estreito. O resultado é convincente, mas ganharia robustez com mais réplicas e uma semente fixa.

Juntas, as duas técnicas completam o ciclo iniciado na Entrega 2: descrever os dados, ajustar um modelo, verificar se ele generaliza e, por fim, quantificar a confiança nas estimativas produzidas.
