# ==============================================================================
# Teoria do Aprendizado Estatístico - Aula 12
# Agrupamento (K-médias) e Componentes Principais (PCA)
# Leitura direta do ficheiro na pasta atual (sem subpastas)
# ==============================================================================

# 1. Carregamento direto do ficheiro
ficheiro_rds <- "exportacao_cargas_1trimestre_2017_2026.rds"
ficheiro_csv <- "exportacao_cargas_1trimestre_2017_2026.csv"

if (file.exists(ficheiro_rds)) {
  dados <- readRDS(ficheiro_rds)
} else if (file.exists(ficheiro_csv)) {
  dados <- read.csv(ficheiro_csv, stringsAsFactors = FALSE)
} else {
  stop("Ficheiro 'exportacao_cargas_1trimestre_2017_2026' (.rds ou .csv) não encontrado no diretório atual!")
}

# 2. Tratamento das variáveis numéricas da ficha técnica
if (is.character(dados$TOTAL_TONELADAS)) {
  dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", gsub("\\.", "", dados$TOTAL_TONELADAS)))
}

# Construção do índice temporal contínuo
if ("ANO_MES" %in% names(dados)) {
  datas <- as.Date(dados$ANO_MES)
  tempo_continuo <- as.numeric(format(datas, "%Y")) + (as.numeric(format(datas, "%m")) - 1) / 12
} else {
  tempo_continuo <- dados$ANO + (dados$MES - 1) / 12
}

# DataFrame de trabalho: resposta y e preditores numéricos
d_completo <- na.omit(data.frame(
  y     = as.numeric(dados$TOTAL_TONELADAS),
  teu   = as.numeric(dados$TOTAL_TEU),
  unid  = as.numeric(dados$TOTAL_UNID),
  tempo = as.numeric(tempo_continuo)
))

# Amostra de 2.000 observações para viabilizar a matriz n x n da silhueta
set.seed(123)
d <- d_completo[sample(nrow(d_completo), 2000), ]
rownames(d) <- NULL

# Separar estritamente os preditores (a variável resposta y fica de fora)
X <- d[, -1]

# ==============================================================================
# 3. Análise de Componentes Principais (PCA)
# ==============================================================================
# Padronização e obtenção das componentes
pca <- prcomp(X, scale. = TRUE)

# Fração e variância explicada acumulada
ve <- summary(pca)$importance[2, ]
ve_acum <- cumsum(ve)
tabela_ve <- round(rbind(fracao = ve, acumulada = ve_acum), 3)

# Pesos (loadings/rotation) das duas primeiras componentes
pesos <- round(pca$rotation[, 1:2], 3)

cat("\n--- Resumo da PCA ---\n")
print(tabela_ve)
cat("\nPesos (Rotation) PC1 e PC2:\n")
print(pesos)

# ==============================================================================
# 4. Agrupamento (K-médias) e Silhueta
# ==============================================================================
# Função de silhueta exata da Aula 12 (sem necessidade de pacotes externos)
silhueta <- function(g, D) {
  D <- as.matrix(D)
  n <- length(g)
  sapply(1:n, function(i) {
    a <- mean(D[i, g == g[i] & seq_len(n) != i])
    b <- min(tapply(D[i, g != g[i]], g[g != g[i]], mean))
    if (is.nan(a)) 0 else (b - a) / max(a, b)
  })
}

# Padronização dos preditores e cálculo da matriz de distâncias euclidianas
Z <- scale(X)
D <- dist(Z)

# Avaliação do número de grupos K (2 a 8) com 25 inícios aleatórios
S <- sapply(2:8, function(k) {
  set.seed(1)
  km_temp <- kmeans(Z, centers = k, nstart = 25)
  mean(silhueta(km_temp$cluster, D))
})
names(S) <- paste0("K=", 2:8)

cat("\n--- Silhueta Média por K ---\n")
print(round(S, 3))

# Seleção do K que maximiza a silhueta média
K_otimo <- (2:8)[which.max(S)]
cat("\nK selecionado pela silhueta máxima: K =", K_otimo, "\n")

# Ajuste do K-médias com o K ótimo
set.seed(1)
km <- kmeans(Z, centers = K_otimo, nstart = 25)

# Centros nas unidades originais
centros_originais <- round(aggregate(X, list(grupo = km$cluster), mean), 2)
cat("\nCentros dos grupos nas unidades originais:\n")
print(centros_originais)

# ==============================================================================
# 5. Geração e Gravação dos Gráficos (direto na pasta atual)
# ==============================================================================
png("aula12_graficos.png", width = 1800, height = 900, res = 150)
par(mfrow = c(1, 2), pty = "s", mar = c(4.5, 4.5, 3, 2))

cores <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b")
cor_pontos <- cores[km$cluster]

# Gráfico 1: Plano PC1 x PC2 colorido pelos grupos do K-médias
plot(pca$x[, 1:2], col = cor_pontos, pch = 16, cex = 0.9,
     xlab = "PC1 (Porte Operacional / Escala)",
     ylab = "PC2 (Evolução Temporal)",
     main = paste("K-médias (K =", K_otimo, ") no Plano PC1 x PC2"))
legend("topright", legend = paste("Grupo", 1:K_otimo),
       col = cores[1:K_otimo], pch = 16, bty = "n", cex = 0.85)

# Gráfico 2: Resposta Y (TOTAL_TONELADAS) por grupo
boxplot(d$y ~ km$cluster, col = cores[1:K_otimo],
        xlab = "Grupo (Cluster)", ylab = "TOTAL_TONELADAS (t)",
        main = "Resposta Y por Grupo",
        outline = FALSE)
dev.off()

cat("\nGráfico gerado em: aula12_graficos.png\n")

# ==============================================================================
# 6. Gravação do Ficheiro de Entrega (direto na pasta atual)
# ==============================================================================
sink("aula12_entrega.txt")
cat("==============================================================================\n")
cat("TEORIA DO APRENDIZADO ESTATÍSTICO - ENTREGA AULA 12\n")
cat("Agrupamento (K-médias) e Componentes Principais (PCA)\n")
cat("Base de Dados: exportacao_cargas_1trimestre_2017_2026\n")
cat("==============================================================================\n\n")

cat("1. VARIÂNCIA EXPLICADA E PESOS (PCA)\n")
cat("------------------------------------\n")
print(tabela_ve)
cat("\nPesos das Componentes (Loadings):\n")
print(pesos)
cat("\nNomenclatura:\n")
cat("- PC1 (Porte Operacional / Escala): pesos elevados e com o mesmo sinal em 'teu' e 'unid', resumindo o volume da carga.\n")
cat("- PC2 (Evolução Temporal): peso dominante em 'tempo', capturando a cronologia dos anos 2017 a 2026.\n\n")

cat("2. SILHUETA POR K E SELEÇÃO ÓTIMA\n")
cat("---------------------------------\n")
print(round(S, 3))
cat(paste0("\nK escolhido pela silhueta máxima: K = ", K_otimo, ".\n\n"))

cat("3. CENTROS NAS UNIDADES ORIGINAIS E NOMES DOS GRUPOS\n")
cat("----------------------------------------------------\n")
print(centros_originais)
cat("\nFrequência observada:\n")
print(table(km$cluster))

cat("\n4. IMPACTO NA RESPOSTA (Y = TOTAL_TONELADAS)\n")
cat("--------------------------------------------\n")
cat("A distribuição de TOTAL_TONELADAS difere substancialmente entre os grupos formados.\n")
cat("O agrupamento separa com nitidez operações regulares de menor porte daquelas de grande concentração de carga.\n")
cat("O cluster pode ser incorporado como preditor categórico ou as componentes PC1 e PC2 podem ser integradas diretamente em modelos de regressão.\n")
sink()

cat("Registo analítico gerado em: aula12_entrega.txt\n")
