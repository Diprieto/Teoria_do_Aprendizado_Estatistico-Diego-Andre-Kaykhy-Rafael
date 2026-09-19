# Entrega 2 — Análise Exploratória dos Dados

**Notebook:** `TrabalhoJP2.ipynb` · **Linguagem:** R

---

## Objetivo

Descrever a base de movimentação de cargas portuárias antes de qualquer modelagem: entender distribuições, identificar outliers, mapear as categorias e visualizar padrões temporais. É o ponto de partida do projeto — nenhuma previsão é feita aqui.

---

## A base

`exportacao_cargas`, com **1.097.014 linhas** cobrindo cerca de duas décadas de operação do complexo portuário.

**Colunas numéricas**
- `TOTAL_TONELADAS` — peso movimentado
- `TOTAL_TEU` — contêineres equivalentes a 20 pés
- `TOTAL_UNID` — número de unidades

**Colunas categóricas**
- `TIPO_NAVEGACAO` (CABOTAGEM / LONGO CURSO), `MOVIMENTO`, `NATUREZA_CARGA`, `SENTIDO` (EMBARQUE / DESEMBARQUE)
- `TERMINAIS`, `MERCADORIAS`, `BERCOS`, `TIPO_INSTALACAO`, `CLASSENAVIO`

**Colunas temporais**
- `ANO`, `MES`, `ANO_MES`, `NUMERO_VIAGEM`

---

## 1. Leitura e tratamento

```r
df <- readRDS("/content/exportacao_cargas.rds")

colunas <- c("TOTAL_TEU", "TOTAL_TONELADAS", "TOTAL_UNID")

# O .rds traz as colunas numéricas como texto com vírgula decimal.
# Converte antes de qualquer cálculo.
for (col in colunas) {
  df[[col]] <- as.numeric(gsub(",", ".", df[[col]]))
}

str(df$TOTAL_TONELADAS)
```

O `.rds` é o mesmo formato usado nas entregas 5, 6 e 7 — mais rápido que CSV, preserva os tipos das colunas e elimina o conflito entre separador de campo e separador decimal.

O laço com `gsub(",", ".", ...)` é indispensável: sem ele, as colunas permanecem como texto e toda média, mediana ou desvio-padrão retorna erro ou `NA`.

---

## 2. Estatísticas descritivas

```r
estatisticas <- data.frame(
  variavel       = colunas,
  media          = sapply(df[colunas], mean, na.rm = TRUE),
  mediana        = sapply(df[colunas], median, na.rm = TRUE),
  desvio_padrao  = sapply(df[colunas], sd, na.rm = TRUE),
  minimo         = sapply(df[colunas], min, na.rm = TRUE),
  maximo         = sapply(df[colunas], max, na.rm = TRUE)
)

print(estatisticas)
```

O `sapply` aplica cada função às três colunas de uma vez, montando a tabela em um único `data.frame`. O que se procura aqui é a **distância entre média e mediana**: quando a média é muito maior, há assimetria à direita e cauda longa de valores altos.

---

## 3. Quartis e detecção de outliers

```r
quartis_estatisticas <- data.frame(
  variavel        = colunas,
  Q1_25pct        = sapply(df[colunas], quantile, probs = 0.25, na.rm = TRUE),
  Mediana_50pct   = sapply(df[colunas], quantile, probs = 0.50, na.rm = TRUE),
  Q3_75pct        = sapply(df[colunas], quantile, probs = 0.75, na.rm = TRUE),
  IQR             = sapply(df[colunas], IQR, na.rm = TRUE),
  Limite_Superior = sapply(df[colunas], function(x) {
    q3  <- quantile(x, 0.75, na.rm = TRUE)
    iqr <- IQR(x, na.rm = TRUE)
    return(q3 + (1.5 * iqr))
  })
)

rownames(quartis_estatisticas) <- NULL
quartis_estatisticas[,-1] <- round(quartis_estatisticas[,-1], 2)

print(quartis_estatisticas)
```

Aplica a **regra de Tukey**: tudo acima de `Q3 + 1,5 × IQR` é candidato a outlier. Esse é o bloco que justifica o cuidado com valores extremos nas entregas seguintes — na Entrega 4, os resíduos do modelo linear chegam a +393.703, confirmando exatamente o que essa tabela antecipa.

Duas correções estéticas no fim: `rownames(...) <- NULL` remove os sufixos automáticos que o `quantile` deixa nos nomes das linhas, e o `round` deixa tudo com 2 casas decimais.

---

## 4. Frequências das variáveis categóricas

```r
colunas_poucas <- c("TIPO_NAVEGACAO", "MOVIMENTO", "NATUREZA_CARGA", "SENTIDO")

for (col in colunas_poucas) {
  cat("---", col, "---\n")
  freq <- sort(table(df[[col]]), decreasing = TRUE)
  print(freq)
  cat("\nProporção (%):\n")
  print(round(prop.table(freq) * 100, 2))
  cat("\n\n")
}

cat("--- TOP 10 TERMINAIS ---\n")
print(head(sort(table(df$TERMINAIS), decreasing = TRUE), 10))

cat("\n--- TOP 10 MERCADORIAS ---\n")
print(head(sort(table(df$MERCADORIAS), decreasing = TRUE), 10))
```

A separação é deliberada: variáveis com poucas categorias aparecem inteiras, com contagem e percentual. `TERMINAIS` e `MERCADORIAS` têm categorias demais para caber na tela, então são cortadas no Top 10.

`prop.table()` converte a contagem em proporção, e a multiplicação por 100 dá o percentual — mais fácil de citar no relatório do que o número absoluto.

---

## 5. Tabelas cruzadas

```r
library(reshape2)

# Evolução dos 5 maiores terminais ao longo dos anos
top5_terminais <- names(sort(table(df$TERMINAIS), decreasing = TRUE))[1:5]
df_top5 <- df[df$TERMINAIS %in% top5_terminais, ]

tab_terminais <- dcast(df_top5, ANO ~ TERMINAIS,
                       value.var = "TOTAL_TONELADAS", fun.aggregate = sum)
print(tab_terminais)

# Natureza da carga × Tipo de navegação
ct1 <- table(df$NATUREZA_CARGA, df$TIPO_NAVEGACAO)
print(ct1)
print(round(prop.table(ct1, margin = 1) * 100, 1))   # % por linha

# Top 8 mercadorias × Sentido
top8_merc <- names(sort(table(df$MERCADORIAS), decreasing = TRUE))[1:8]
df_top8 <- df[df$MERCADORIAS %in% top8_merc, ]
ct2 <- table(df_top8$MERCADORIAS, df_top8$SENTIDO)
print(ct2)
```

O `dcast` transforma o formato longo em largo: anos nas linhas, terminais nas colunas, soma de toneladas nas células — é a tabela que mostra se algum terminal ganhou ou perdeu participação ao longo do tempo.

O `margin = 1` no `prop.table` calcula percentual **por linha**, respondendo "dentro de cada natureza de carga, quanto é cabotagem e quanto é longo curso?". Esse cruzamento antecipa a Entrega 5, que modela justamente a relação entre tipo de navegação e sentido.

---

## 6. Visualizações

```r
# 1. Boxplot - outliers por natureza da carga (escala log)
boxplot(log10(df$TOTAL_TONELADAS + 1) ~ df$NATUREZA_CARGA,
        main = "Distribuição de TOTAL_TONELADAS por natureza da carga (escala log)",
        xlab = "Natureza da carga", ylab = "log10(Toneladas + 1)",
        col = "lightblue", las = 2)

# 2. Histograma - forma da distribuição
hist(log10(df$TOTAL_TONELADAS + 1),
     main = "Distribuição de TOTAL_TONELADAS (escala log)",
     xlab = "log10(Toneladas + 1)", col = "steelblue", breaks = 40)

# 3. Linha do tempo - evolução anual
por_ano <- aggregate(TOTAL_TONELADAS ~ ANO, data = df, sum)
plot(por_ano$ANO, por_ano$TOTAL_TONELADAS / 1e6, type = "b", pch = 19, col = "steelblue",
     xlab = "Ano", ylab = "Milhões de toneladas",
     main = "Evolução do volume de carga por ano")

# 4. Barras - ranking dos terminais (top 10)
top10_terminais <- sort(tapply(df$TOTAL_TONELADAS, df$TERMINAIS, sum), decreasing = TRUE)[1:10]
barplot(top10_terminais / 1e6, las = 2, col = "darkorange",
        main = "Top 10 terminais por volume (milhões de toneladas)",
        ylab = "Milhões de toneladas", cex.names = 0.7)
```

| Gráfico | O que revela |
|---|---|
| Boxplot | Cada natureza de carga tem distribuição própria — granel sólido opera em outra ordem de grandeza |
| Histograma | Forma da distribuição e confirmação da assimetria |
| Série temporal | Tendência de crescimento do volume, base da Entrega 4 |
| Barras | Concentração da movimentação em poucos terminais |

**Sobre a escala log:** a transformação `log10(x + 1)` aparece em todos os gráficos de toneladas. Sem ela, os outliers achatam a visualização e a maioria dos pontos vira uma única faixa colada no eixo. O `+ 1` evita `log(0)`, que retornaria `-Inf` nos registros com volume zero.

---

## Pontos de atenção

- **Escolha do formato.** A versão original lia `/content/exportacao_cargas (2).csv` com `sep = ","` e `dec = ","` ao mesmo tempo. Usar o mesmo caractere como separador de campo e de decimal quebra a leitura. O `.rds` resolve isso na origem.
- **Dependência em cadeia.** `df` e `colunas` são criados na primeira célula. Se ela falhar, nenhuma das demais roda — sempre confirmar que a primeira executou antes de seguir.
- **`na.rm = TRUE` em toda parte.** Necessário, mas vale conferir quantos `NA` existem de fato: se forem muitos, a média está sendo calculada sobre um subconjunto que pode não representar o total.

---

## Conclusão

A exploração estabelece três fatos que orientam todas as entregas seguintes:

1. A distribuição de `TOTAL_TONELADAS` é **fortemente assimétrica**, com outliers relevantes
2. O comportamento **difere muito por `NATUREZA_CARGA`** — motivo pelo qual essa variável entra no modelo da Entrega 4
3. Existe **tendência temporal** no volume agregado, o que justifica a regressão contra o tempo

A assimetria detectada aqui é o fio condutor do projeto: reaparece nos resíduos da Entrega 4, motiva a transformação logarítmica e explica a heterocedasticidade observada nos diagnósticos.
