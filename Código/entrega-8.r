# ==============================================================================
# LABORATÓRIO: RIDGE & LASSO - REGULARIZAÇÃO NO 1º TRIMESTRE (2017-2026)
# Disciplina: Teoria do Aprendizado Estatístico (Fatec Rubens Lara)
# ==============================================================================

# Instalação e carregamento de pacotes necessários
if(!require(ggplot2)) install.packages("ggplot2")
if(!require(dplyr))   install.packages("dplyr")
if(!require(glmnet))  install.packages("glmnet")

library(ggplot2)
library(dplyr)
library(glmnet)

# ------------------------------------------------------------------------------
# 1. CARREGAMENTO E TRATAMENTO DOS DADOS
# ------------------------------------------------------------------------------
dados <- readRDS("/content/exportacao_cargas_1trimestre_2017_2026.rds")

# Conversão de numéricos (vírgula para ponto)
dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", gsub("\\.", "", dados$TOTAL_TONELADAS)))
dados$TOTAL_TEU       <- as.numeric(gsub(",", ".", gsub("\\.", "", dados$TOTAL_TEU)))

# Limpeza de valores ausentes (NAs)
dados_limpos <- subset(dados,
                       !is.na(TOTAL_TONELADAS) &
                       !is.na(TOTAL_TEU) &
                       !is.na(SENTIDO) &
                       !is.na(TIPO_NAVEGACAO))

# ------------------------------------------------------------------------------
# 2. CONFIGURAÇÃO DA MATRIZ DE MODELO (X) E RESPOSTA (y)
# ------------------------------------------------------------------------------
# glmnet exige uma matriz X numérica (expandindo categóricas em dummies)
# Removemos a coluna do intercepto ([, -1]) pois o glmnet gerencia o beta_0
X  <- model.matrix(TOTAL_TONELADAS ~ . - 1, data = dados_limpos)
yv <- dados_limpos$TOTAL_TONELADAS

cat("Dimensões da Matriz X (Observações x Preditores):", dim(X), "\n\n")

# ------------------------------------------------------------------------------
# 3. RIDGE (L2) E LASSO (L1) VIA VALIDAÇÃO CRUZADA
# ------------------------------------------------------------------------------
set.seed(1) # Para reprodutibilidade das dobras (folds) da Validação Cruzada

# Ajuste Ridge (alpha = 0) e Lasso (alpha = 1)
cvr <- cv.glmnet(X, yv, alpha = 0) # Ridge
cvl <- cv.glmnet(X, yv, alpha = 1) # Lasso

# ------------------------------------------------------------------------------
# 4. EXIBIÇÃO DAS CURVAS EM U (VALIDAÇÃO CRUZADA)
# ------------------------------------------------------------------------------
par(mfrow = c(1, 2), mar = c(4, 4, 3.5, 1), pty = "s")

# Gráfico Curva em U - Ridge
plot(cvr, main = "Ridge (L2) - Curva em U")

# Gráfico Curva em U - Lasso
plot(cvl, main = "Lasso (L1) - Curva em U")

# Restaurar layout padrão de gráficos
par(mfrow = c(1, 1))

# ------------------------------------------------------------------------------
# 5. LAMBDAS ESCOLHIDOS E SELEÇÃO DE PREDITORES (LASSO)
# ------------------------------------------------------------------------------
lambda_min_lasso <- cvl$lambda.min
lambda_1se_lasso <- cvl$lambda.1se

cat("=== RESULTADOS DO LASSO (L1) ===\n")
cat("Lambda Mínimo (lambda.min) :", round(lambda_min_lasso, 4), "\n")
cat("Lambda 1SE    (lambda.1se) :", round(lambda_1se_lasso, 4), "\n\n")

# Preditores que sobreviveram à penalização com a regra do 1-EP (lambda.1se)
coef_1se <- coef(cvl, s = "lambda.1se")
preditores_sobreviventes <- coef_1se[as.vector(coef_1se) != 0, , drop = FALSE]

cat("--- PREDITORES SOBREVIVENTES (lambda.1se) ---\n")
print(round(preditores_sobreviventes, 4))
cat("\n")

# ------------------------------------------------------------------------------
# 6. COMPARAÇÃO DO ERRO DE CV (MSE e RMSE)
# ------------------------------------------------------------------------------
mse_ridge_min <- min(cvr$cvm)
mse_lasso_min <- min(cvl$cvm)
mse_lasso_1se <- cvl$cvm[cvl$lambda == cvl$lambda.1se]

placar_modelos <- data.frame(
  Modelo = c("Ridge (lambda.min)", "Lasso (lambda.min)", "Lasso (lambda.1se)"),
  CV_MSE = round(c(mse_ridge_min, mse_lasso_min, mse_lasso_1se), 2),
  CV_RMSE = round(sqrt(c(mse_ridge_min, mse_lasso_min, mse_lasso_1se)), 2)
)

cat("=== COMPARATIVO DE DESEMPENHO (VALIDAÇÃO CRUZADA) ===\n")
print(placar_modelos)
cat("\n")

# ------------------------------------------------------------------------------
# 7. SÍNTESE DO PROBLEMA / CONCLUSÃO PARA O RELATÓRIO
# ------------------------------------------------------------------------------
n_vars_total <- ncol(X)
n_vars_lasso <- length(preditores_sobreviventes) - 1 # desconsiderando intercepto

cat("=== SÍNTESE/FRASE PARA O RELATÓRIO ===\n")
cat(sprintf(
  "O Lasso reduziu a complexidade do modelo de %d para %d preditores ativos usando a regra de 1 erro padrão (lambda.1se = %.4f). As variáveis selecionadas indicam quais atributos carregam o sinal preditivo principal para o volume de carga exportada no 1º trimestre, descartando o ruído e reduzindo a variância dos coeficientes.",
  n_vars_total, n_vars_lasso, lambda_1se_lasso
))