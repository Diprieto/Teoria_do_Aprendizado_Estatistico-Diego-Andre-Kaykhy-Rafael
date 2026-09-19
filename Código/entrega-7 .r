# Lembre-se de verificar se o arquivo aa está na pastinha do Colab
dados <- readRDS("/content/exportacao_cargas.rds")

# Rodar o tratamento novamente
dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", dados$TOTAL_TONELADAS))
dados$TOTAL_TEU <- as.numeric(dados$TOTAL_TEU)
dados$TOTAL_UNID <- as.numeric(dados$TOTAL_UNID)

# 1. Prepara as dobras
k <- 5
d <- sample(rep(1:k, length = nrow(dados)))

# 2. Cria a função com a sua coluna TOTAL_TONELADAS
cv <- function(formula) mean(sapply(1:k, function(j) {
    m <- lm(formula, data = dados[d != j, ])

    # Calculando o erro médio usando TOTAL_TONELADAS
    mean((dados$TOTAL_TONELADAS[d == j] - predict(m, dados[d == j, ]))^2, na.rm = TRUE)
}))

# m1: Toneladas explicadas pelo número de TEU
# m2: Toneladas explicadas pelo número de TEU + número de unidades
resultados_cv <- c(m1 = cv(TOTAL_TONELADAS ~ TOTAL_TEU), m2 = cv(TOTAL_TONELADAS ~ TOTAL_TEU + TOTAL_UNID))
print("Resultados da Validação Cruzada:")
print(resultados_cv)

# 4. Bootstrap do Coeficiente (Assumindo que o m2 venceu)
# Estamos isolando e reamostrando 2000 vezes o coeficiente da coluna TOTAL_TEU
b <- replicate(20, {
  i <- sample(nrow(dados), nrow(dados), replace = TRUE)
  coef(lm(TOTAL_TONELADAS ~ TOTAL_TEU + TOTAL_UNID, data = dados[i, ]))["TOTAL_TEU"]
})

# 5. Cálculo do Erro Padrão e Intervalo de Confiança
resultados_boot <- c(ep = sd(b), quantile(b, c(0.025, 0.975), na.rm = TRUE))
print("Resultados do Bootstrap:")
print(resultados_boot)