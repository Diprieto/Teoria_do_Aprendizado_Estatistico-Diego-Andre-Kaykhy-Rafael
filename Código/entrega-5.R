# ==============================================================================
# AULA 5 - REGRESSÃO LOGÍSTICA BINÁRIA (Corrigido para 1.097.014 linhas)
# ==============================================================================

suppressPackageStartupMessages(library(dplyr))

exportacao_cargas <- readRDS("/content/exportacao_cargas.rds")

# ------------------------------------------------------------------------------
# 1. Tratamento dos Dados
# ------------------------------------------------------------------------------
dados_modelo <- exportacao_cargas %>%
  mutate(
    # Binarizar SENTIDO: 1 = DESEMBARQUE, 0 = EMBARQUE
    y_sentido = as.integer(SENTIDO == "DESEMBARQUE"),

    # Corrigir vírgula para ponto e converter para numérico
    TOTAL_TONELADAS = as.numeric(gsub(",", ".", TOTAL_TONELADAS)),

    # Converter colunas categóricas usando os nomes corretos do seu str()
    TIPO_NAVEGACAO = as.factor(TIPO_NAVEGACAO),
    NATUREZA_CARGA = as.factor(NATUREZA_CARGA)
  ) %>%
  # Remover linhas com NA nas variáveis do modelo
  filter(!is.na(y_sentido), !is.na(TOTAL_TONELADAS))

# Exibir distribuição da resposta
cat("\n--- Distribuição da Variável Resposta (y_sentido) ---\n")
print(table(dados_modelo$y_sentido))
print(prop.table(table(dados_modelo$y_sentido)))

# ------------------------------------------------------------------------------
# 2. Ajuste do Modelo Logístico (glm)
# ------------------------------------------------------------------------------
# Prever DESEMBARQUE com base no Peso e no Tipo de Navegação
modelo_logistico <- glm(
  y_sentido ~ TOTAL_TONELADAS + TIPO_NAVEGACAO,
  family = binomial(link = "logit"),
  data = dados_modelo
)

# Resumo do modelo (Coeficientes no Logit)
summary(modelo_logistico)

# ------------------------------------------------------------------------------
# 3. Razões de Chance (Odds Ratios - exp(beta))
# ------------------------------------------------------------------------------
cat("\n==================================================\n")
cat("RAZÕES DE CHANCE (Odds Ratios - exp(beta)):\n")
cat("==================================================\n")
razoes_chance <- exp(coef(modelo_logistico))
print(round(razoes_chance, 4))

# ------------------------------------------------------------------------------
# 4. Probabilidades Preditas e Matrizes de Confusão (0.3, 0.5 e 0.7)
# ------------------------------------------------------------------------------
# Gerar probabilidade predita
dados_modelo$prob_predita <- predict(modelo_logistico, type = "response")

# Matrizes de Confusão nos 3 limiares
for (limiar in c(0.3, 0.5, 0.7)) {
  pred_classe <- as.integer(dados_modelo$prob_predita > limiar)
  cat(paste0("\n--- Matriz de Confusão (Limiar c = ", limiar, ") ---\n"))
  matriz <- table(Real = dados_modelo$y_sentido, Previsto = pred_classe)
  print(matriz)

  acuracia <- mean(pred_classe == dados_modelo$y_sentido)
  cat("Acurácia:", round(acuracia, 4), "\n")
}

# ------------------------------------------------------------------------------
# 5. Área Sob a Curva ROC (AUC em Amostra Rápida para >1Mi de dados)
# ------------------------------------------------------------------------------
# Amostragem para cálculo rápido da AUC sem estourar a memória RAM do Colab
set.seed(42)
amostra_auc <- dados_modelo %>% sample_n(min(50000, nrow(dados_modelo)))

p_pos <- amostra_auc$prob_predita[amostra_auc$y_sentido == 1]
p_neg <- amostra_auc$prob_predita[amostra_auc$y_sentido == 0]

auc <- mean(outer(p_pos, p_neg, ">"))
cat("\n==================================================\n")
cat("AUC (Área sob a Curva ROC - Amostra 50k):", round(auc, 4), "\n")
cat("==================================================\n")
