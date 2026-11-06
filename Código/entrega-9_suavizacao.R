# ==============================================================================
# Aula 9: Métodos de Suavização (KNN-regressão e Kernel Smoothing)
# Disciplina: Teoria do Aprendizado Estatístico - Fatec Baixada Santista
# Resposta (Y): TOTAL_TONELADAS | Preditor (X): TOTAL_TEU
# ==============================================================================

# 1. Carregamento e Preparação dos Dados ----------------------------------------
if (file.exists("exportacao_cargas.rds")) {
  dados <- readRDS("exportacao_cargas.rds")
} else if (file.exists("exportacao_cargas_1trimestre_2017_2026.rds")) {
  dados <- readRDS("exportacao_cargas_1trimestre_2017_2026.rds")
} else {
  dados <- read.csv("exportacao_cargas.csv", stringsAsFactors = FALSE)
}

# Definição das variáveis do laboratório
x_bruto <- as.numeric(dados$TOTAL_TEU)
y_bruto <- as.numeric(dados$TOTAL_TONELADAS)

# Filtro de registros válidos e positivos
ok <- !is.na(x_bruto) & !is.na(y_bruto) & x_bruto > 0 & y_bruto > 0
x_valido <- x_bruto[ok]
y_valido <- y_bruto[ok]

# Amostragem representativa para cálculo de distância viável em R
set.seed(42)
n_amostra <- min(2000, length(y_valido))
idx <- sample(seq_along(y_valido), size = n_amostra)
x <- x_valido[idx]
y <- y_valido[idx]

# 2. Definição dos Modelos da Aula ---------------------------------------------
# KNN-Regressão
knn_reg <- function(xo, x, y, k) {
  mean(y[order(abs(x - xo))[1:k]])
}

# Kernel Gaussiano (Nadaraya-Watson)
nw <- function(xo, x, y, h) {
  w <- dnorm((x - xo) / h)
  if (sum(w) == 0) return(mean(y)) # Evita divisão por zero/NaN em regiões ralas
  sum(w * y) / sum(w)
}

# Reta (Mínimos Quadrados)
reta <- function(xo, x, y) {
  sum(coef(lm(y ~ x)) * c(1, xo))
}

# 3. Validação Cruzada em 5 Dobras ---------------------------------------------
set.seed(1)
dobra <- sample(rep(1:5, length = length(y)))

cv_de <- function(prever) {
  mean(sapply(1:5, function(j) {
    tr <- dobra != j
    va <- dobra == j
    mean((y[va] - sapply(x[va], prever, x = x[tr], y = y[tr]))^2)
  }))
}

cat("Calculando CV(5) para a Reta...\n")
cv_reta <- cv_de(reta)

# Teste de hiperparâmetros de k
ks <- c(3, 5, 10, 20, 40)
ks <- ks[ks < 0.8 * length(y)]
cat("Calculando CV(5) para KNN...\n")
cv_knn_valores <- sapply(ks, function(k) {
  cv_de(function(xo, x, y) knn_reg(xo, x, y, k))
})
melhor_k <- ks[which.min(cv_knn_valores)]
cv_knn_melhor <- min(cv_knn_valores)

# Teste de hiperparâmetros de banda h
# Caso a densidade cause NaNs em h muito estreito, os multiplicadores evitam janelas vazias
hs <- sd(x) * c(0.05, 0.1, 0.2, 0.4)
cat("Calculando CV(5) para Kernel...\n")
cv_kernel_valores <- sapply(hs, function(h) {
  cv_de(function(xo, x, y) nw(xo, x, y, h))
})
melhor_h <- hs[which.min(cv_kernel_valores)]
cv_kernel_melhor <- min(cv_kernel_valores)

# 4. Exibição e Salvamento dos Resultados --------------------------------------
dir.create("consolidados", showWarnings = FALSE)

# Gráfico do melhor modelo de Kernel
png("consolidados/melhor_kernel.png", width = 800, height = 600, res = 100)
par(mar = c(4.5, 4.5, 2.5, 1))
g <- seq(min(x), max(x), length = 300)
pred_grid <- sapply(g, nw, x = x, y = y, h = melhor_h)

plot(x, y, pch = 16, col = rgb(0.3, 0.3, 0.3, 0.4),
     xlab = "Total TEU (x)", ylab = "Total Toneladas (y)",
     main = paste0("Kernel Smoothing (Nadaraya-Watson, h = ", round(melhor_h, 2), ")"))
lines(g, pred_grid, col = "#1b9e77", lwd = 2.5)
dev.off()

# Resumo impresso no terminal
cat("\n=== RESULTADOS DA VALIDAÇÃO CRUZADA ===\n")
cat(sprintf("Reta (Linear)  - MSE: %.2f\n", cv_reta))
cat(sprintf("KNN (k = %d)    - MSE: %.2f\n", melhor_k, cv_knn_melhor))
cat(sprintf("Kernel (h = %.2f) - MSE: %.2f\n", melhor_h, cv_kernel_melhor))
