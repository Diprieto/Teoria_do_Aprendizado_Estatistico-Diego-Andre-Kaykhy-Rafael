# ==============================================================================
# 1. Carregamento e Estatísticas Iniciais
# ==============================================================================
df <- readRDS("/content/exportacao_cargas.rds")
str(df$TOTAL_TONELADAS)

colunas <- c("TOTAL_TEU", "TOTAL_TONELADAS", "TOTAL_UNID")
estatisticas <- data.frame(
  variavel       = colunas,
  media          = sapply(df[colunas], mean, na.rm = TRUE),
  mediana        = sapply(df[colunas], median, na.rm = TRUE),
  desvio_padrao  = sapply(df[colunas], sd, na.rm = TRUE),
  minimo         = sapply(df[colunas], min, na.rm = TRUE),
  maximo         = sapply(df[colunas], max, na.rm = TRUE)
)
print(estatisticas)

# ==============================================================================
# 2. Pré-processamento e Cálculo de Quartis
# ==============================================================================
# Pre-processamento: converter colunas para numérico, tratando vírgulas como decimais
# Isso é importante porque o erro "non-numeric argument to binary operator"
# indica que as funções estatísticas estão recebendo dados não numéricos.
# A saída de str(df$TOTAL_TONELADAS) mostra que TOTAL_TONELADAS é do tipo 'chr'
# e usa vírgula como separador decimal, o que impede que seja tratada como número.
for (col in colunas) {
  if (is.character(df[[col]])) {
    df[[col]] <- as.numeric(gsub(",", ".", df[[col]]))
  }
}

# Calcular estatísticas com nomes limpos e arredondados
quartis_estatisticas <- data.frame(
  variavel        = colunas,
  Q1_25pct        = sapply(df[colunas], quantile, probs = 0.25, na.rm = TRUE),
  Mediana_50pct   = sapply(df[colunas], quantile, probs = 0.50, na.rm = TRUE),
  Q3_75pct        = sapply(df[colunas], quantile, probs = 0.75, na.rm = TRUE),
  IQR             = sapply(df[colunas], IQR, na.rm = TRUE),
  Limite_Superior = sapply(df[colunas], function(x) {
    q3 <- quantile(x, 0.75, na.rm = TRUE)
    iqr <- IQR(x, na.rm = TRUE)
    return(q3 + (1.5 * iqr))
  })
)

# Correção estética: remove os sufixos feios dos nomes das linhas
rownames(quartis_estatisticas) <- NULL

# Arredonda tudo para 2 casas decimais para facilitar a leitura
quartis_estatisticas[, -1] <- round(quartis_estatisticas[, -1], 2)

# Exibir a tabela formatada
print(quartis_estatisticas)

# ==============================================================================
# 3. Análise de Variáveis Categóricas
# ==============================================================================
# Variáveis categóricas com poucas categorias -> mostrar frequência completa
colunas_poucas <- c("TIPO_NAVEGACAO", "MOVIMENTO", "NATUREZA_CARGA", "SENTIDO")
for (col in colunas_poucas) {
  cat("---", col, "---\n")
  freq <- sort(table(df[[col]]), decreasing = TRUE)
  print(freq)
  cat("\nProporção (%):\n")
  print(round(prop.table(freq) * 100, 2))
  cat("\n\n")
}

# TERMINAIS e MERCADORIAS têm muitas categorias -> mostrar só o Top 10
cat("--- TOP 10 TERMINAIS ---\n")
print(head(sort(table(df$TERMINAIS), decreasing = TRUE), 10))

cat("\n--- TOP 10 MERCADORIAS ---\n")
print(head(sort(table(df$MERCADORIAS), decreasing = TRUE), 10))

# ==============================================================================
# 4. Cruzamentos e Participação
# ==============================================================================
# 1. Evolução da participação dos terminais ao longo dos anos
# Verifica se o pacote 'reshape2' está instalado; se não estiver, instala.
if (!require(reshape2)) {
  install.packages("reshape2")
  library(reshape2)
} else {
  library(reshape2)
}

top5_terminais <- names(sort(table(df$TERMINAIS), decreasing = TRUE))[1:5]
df_top5 <- df[df$TERMINAIS %in% top5_terminais, ]

tab_terminais <- dcast(df_top5, ANO ~ TERMINAIS, value.var = "TOTAL_TONELADAS", fun.aggregate = sum)
print(tab_terminais)

# 2. Natureza da carga x Tipo de navegação
ct1 <- table(df$NATUREZA_CARGA, df$TIPO_NAVEGACAO)
print(ct1)
print(round(prop.table(ct1, margin = 1) * 100, 1))   # % por linha

# 3. Mercadorias (top 8) x Sentido
top8_merc <- names(sort(table(df$MERCADORIAS), decreasing = TRUE))[1:8]
df_top8 <- df[df$MERCADORIAS %in% top8_merc, ]

ct2 <- table(df_top8$MERCADORIAS, df_top8$SENTIDO)
print(ct2)

# ==============================================================================
# 5. Visualizações Gráficas
# ==============================================================================
# 1. Boxplot - outliers em TOTAL_TONELADAS (escala log, já que a distribuição é bem assimétrica)
boxplot(log10(df$TOTAL_TONELADAS + 1) ~ df$NATUREZA_CARGA,
        main = "Distribuição de TOTAL_TONELADAS por natureza da carga (escala log)",
        xlab = "Natureza da carga", ylab = "log10(Toneladas + 1)",
        col = "lightblue", las = 2)

# 2. Histograma - forma da distribuição
# Nota: O final do código original deste bloco estava truncado na visualização.
hist(log10(df$TOTAL_TONELADAS + 1))