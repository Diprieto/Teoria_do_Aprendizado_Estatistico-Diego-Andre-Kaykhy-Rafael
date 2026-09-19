# Instalar ggplot2 caso não esteja instalado no ambiente R do Colab
if(!require(ggplot2)) install.packages("ggplot2")
library(ggplot2)

# 1. Carregar os dados
# (Se der erro de colunas misturadas, mude sep = "," para sep = ";")

dados <- readRDS("/content/exportacao_cargas.rds")


# Forçar a conversão de texto para número (substituindo vírgula por ponto decimal)
dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", dados$TOTAL_TONELADAS))
dados$TOTAL_TEU <- as.numeric(gsub(",", ".", dados$TOTAL_TEU))

# Limpeza: remover as linhas vazias (NAs)
dados_limpos <- subset(dados, !is.na(TOTAL_TONELADAS) &
                              !is.na(TOTAL_TEU) &
                              !is.na(SENTIDO) &
                              !is.na(TIPO_NAVEGACAO))

# 2. Dividir 70/30 ANTES de qualquer ajuste
set.seed(1)
n_linhas <- nrow(dados_limpos)
itr <- sample(n_linhas, round(0.7 * n_linhas))

tr <- dados_limpos[itr, ]   # Base de Treino (70%)
te <- dados_limpos[-itr, ]  # Base de Teste (30%)

# 3. Ajustar DOIS candidatos só no treino
m1 <- lm(TOTAL_TONELADAS ~ TOTAL_TEU, data = tr)
m2 <- lm(TOTAL_TONELADAS ~ TOTAL_TEU + SENTIDO + TIPO_NAVEGACAO, data = tr)

# 4. Comparar no TESTE (e também no TREINO para o gráfico)
mse <- function(m, d) {
  mean((d$TOTAL_TONELADAS - predict(m, d))^2, na.rm = TRUE)
}

# Calculando RMSE (raiz quadrada do MSE)
rmse_m1_tr <- sqrt(mse(m1, tr)) # Treino M1
rmse_m1_te <- sqrt(mse(m1, te)) # Teste M1

rmse_m2_tr <- sqrt(mse(m2, tr)) # Treino M2
rmse_m2_te <- sqrt(mse(m2, te)) # Teste M2

# Exibir os resultados em texto para preencher o trabalho
cat("=== RESULTADOS PARA O TRABALHO ===\n")
cat("RMSE Candidato 1 (Teste): ", round(rmse_m1_te, 2), "\n")
cat("RMSE Candidato 2 (Teste): ", round(rmse_m2_te, 2), "\n\n")

if(rmse_m1_te < rmse_m2_te) {
  cat("VENCEDOR: Candidato 1 possui o menor erro de teste.\n")
} else {
  cat("VENCEDOR: Candidato 2 possui o menor erro de teste.\n")
}

# 5. GERAR O GRÁFICO COMPARATIVO
# Organizando os dados para o ggplot
dados_grafico <- data.frame(
  Modelo = rep(c("Candidato 1\n(Simples)", "Candidato 2\n(Múltiplo)"), each = 2),
  Conjunto = rep(c("1. Treino", "2. Teste"), times = 2),
  RMSE = c(rmse_m1_tr, rmse_m1_te, rmse_m2_tr, rmse_m2_te)
)

# Plotando
ggplot(dados_grafico, aes(x = Modelo, y = RMSE, fill = Conjunto)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = round(RMSE, 0)),
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 4) +
  # AQUI: Mudando as cores para Azul e Vermelho
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
    legend.position = "top",
    text = element_text(size = 12)
  )