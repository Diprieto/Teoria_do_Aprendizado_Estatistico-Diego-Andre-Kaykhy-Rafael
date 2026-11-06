# ==============================================================================
# Laboratório Aula 11 - Árvores de Decisão e Random Forest
# Disciplina: Teoria do Aprendizado Estatístico - Fatec Baixada Santista
# Base: exportacao_cargas_1trimestre_2017_2026.rds (Porto de Santos)
# ==============================================================================

# Instalação dos pacotes necessários (se ausentes)
if (!requireNamespace("randomForest", quietly = TRUE)) {
  install.packages("randomForest", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("rpart", quietly = TRUE)) {
  install.packages("rpart")
}

library(rpart)
library(randomForest)

# 1. Carregamento dos dados
candidatos_caminho <- c(
  "exportacao_cargas_1trimestre_2017_2026.rds",
  file.path("dados", "exportacao_cargas_1trimestre_2017_2026.rds"),
  file.path("..", "dados", "exportacao_cargas_1trimestre_2017_2026.rds"),
  "/content/exportacao_cargas_1trimestre_2017_2026.rds"
)
caminho_dados <- candidatos_caminho[file.exists(candidatos_caminho)][1]

if (is.na(caminho_dados)) {
  stop("Arquivo .rds não encontrado. Verifique a pasta atual com getwd().")
}

dados <- readRDS(caminho_dados)

# 2. Definição do tempo contínuo
if ("tempo_continuo" %in% names(dados)) {
  tempo_var <- dados$tempo_continuo
} else if ("tempo" %in% names(dados)) {
  tempo_var <- dados$tempo
} else {
  tempo_var <- dados$ANO + (dados$MES - 1) / 12
}

# 3. Construção do data frame com os preditores da Entrega 1
d <- na.omit(data.frame(
  y         = as.numeric(dados$TOTAL_TONELADAS),
  tempo     = as.numeric(tempo_var),
  teu       = as.numeric(dados$TOTAL_TEU),
  natureza  = as.factor(dados$NATUREZA_CARGA),
  navegacao = as.factor(dados$TIPO_NAVEGACAO)
))

# 4. Amostra de 5.000 linhas para viabilizar o randomForest (slide 27)
set.seed(1)
if (nrow(d) > 5000) {
  d <- d[sample(nrow(d), 5000), ]
}

# 5. Dobras da Validação Cruzada (mesmas dobras para toda a turma)
set.seed(1)
dobra <- sample(rep(1:5, length.out = nrow(d)))

# ------------------------------------------------------------------------------
# 6. Árvore de Regressão e Poda por Custo-Complexidade (rpart)
# ------------------------------------------------------------------------------
cheia <- rpart(y ~ ., data = d, cp = 0.001, xval = dobra)
tab <- cheia$cptable

# Fundo da curva em U de validação cruzada
i_min <- which.min(tab[, "xerror"])
cp_otimo <- tab[i_min, "CP"]
arv_podada <- prune(cheia, cp = cp_otimo)

# Cálculo do CV(5) MSE e RMSE
variancia_y <- mean((d$y - mean(d$y))^2)
mse_cv_arv <- tab[i_min, "xerror"] * variancia_y
rmse_cv_arv <- sqrt(mse_cv_arv)
folhas_arv <- tab[i_min, "nsplit"] + 1

cat(sprintf("\n--- ÁRVORE PODADA ---\n"))
cat(sprintf("Folhas: %d | cp: %.5f | MSE CV(5): %.2f | RMSE CV(5): %.2f toneladas\n",
            folhas_arv, cp_otimo, mse_cv_arv, rmse_cv_arv))

# Exportação gráfica da árvore podada (maxdepth = 3 para legibilidade visual)
dir.create("figuras", showWarnings = FALSE)
arv_vis <- rpart(y ~ ., data = d, maxdepth = 3, cp = cp_otimo)

png("figuras/aula11_arvore_podada.png", width = 1000, height = 700, res = 120)
par(pty = "s", mar = c(1, 1, 2, 1))
plot(arv_vis, uniform = TRUE, branch = 0.5, margin = 0.1)
text(arv_vis, cex = 0.75, digits = 3)
title("Árvore de Regressão Podada (Primeiros 3 Níveis)")
dev.off()

# ------------------------------------------------------------------------------
# 7. Floresta Aleatória e Escolha de mtry via Erro OOB
# ------------------------------------------------------------------------------
p <- ncol(d) - 1
ms_candidatos <- unique(pmax(1, round(c(sqrt(p), p/3, p/2, p))))

oob_mses <- sapply(ms_candidatos, function(m) {
  set.seed(1)
  tail(randomForest(y ~ ., data = d, mtry = m, ntree = 500)$mse, 1)
})

m_otimo <- ms_candidatos[which.min(oob_mses)]

cat(sprintf("\n--- FLORESTA ALEATÓRIA ---\n"))
cat(sprintf("Valores mtry testados: %s\n", paste(ms_candidatos, collapse = ", ")))
cat(sprintf("Melhor mtry (via OOB): %d (MSE OOB: %.2f)\n", m_otimo, min(oob_mses)))

# Modelo final com 500 árvores e importância
set.seed(1)
rf_final <- randomForest(y ~ ., data = d, mtry = m_otimo, ntree = 500, importance = TRUE)

mse_oob_rf <- tail(rf_final$mse, 1)
rmse_oob_rf <- sqrt(mse_oob_rf)

cat(sprintf("Random Forest Final - OOB MSE: %.2f | OOB RMSE: %.2f toneladas\n\n", mse_oob_rf, rmse_oob_rf))

# Exportação da importância dos preditores
png("figuras/aula11_importancia_preditores.png", width = 850, height = 600, res = 120)
par(pty = "s", mar = c(4, 7, 2, 1))
varImpPlot(rf_final, scale = FALSE, main = "Importância dos Preditores (Random Forest)")
dev.off()

# ------------------------------------------------------------------------------
# 8. Placar Comparativo Consolidado
# ------------------------------------------------------------------------------
placar <- data.frame(
  Modelo = c("Linha de Base", "MQO Linear (Aula 4)", "GAM (Aula 10)", "Árvore Podada (Aula 11)", "Random Forest (Aula 11)"),
  Configuracao = c("Média", "Retas lineares", "s(tempo) + s(TOTAL_TEU)", sprintf("%d folhas (cp = %.4f)", folhas_arv, cp_otimo), sprintf("mtry = %d, B = 500", m_otimo)),
  MSE_Validacao = c(88336313, 30162283, 30144272, mse_cv_arv, mse_oob_rf),
  RMSE_Validacao = c(9398.74, 5492.02, 5490.38, rmse_cv_arv, rmse_oob_rf)
)

print(placar)
