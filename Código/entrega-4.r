dados <- readRDS("/content/exportacao_cargas.rds")

# O .rds traz as colunas numéricas como texto com vírgula decimal.
# Converte antes de usar no modelo.
dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", dados$TOTAL_TONELADAS))
dados$TOTAL_TEU       <- as.numeric(gsub(",", ".", dados$TOTAL_TEU))
dados$TOTAL_UNID      <- as.numeric(gsub(",", ".", dados$TOTAL_UNID))

head(dados, n = 5)

# 1. Preparação da variável temporal contínua (X)
# Extraímos o ano e o mês, e transformamos em um número decimal
# (ex: Janeiro de 2020 vira 2020.000, Fevereiro vira 2020.083)
dados$ano <- as.numeric(substr(dados$ANO_MES, 1, 4))
dados$mes <- as.numeric(substr(dados$ANO_MES, 6, 7))
dados$tempo_continuo <- dados$ano + (dados$mes - 1) / 12

# 2. Ajuste da regressão linear simples
# O modelo lm() ajustará a reta minimizando a soma dos quadrados dos resíduos
# Adicionando a natureza da carga e o tipo de navegação ao lado do tempo
m_multiplo <- lm(TOTAL_TONELADAS ~ tempo_continuo + NATUREZA_CARGA + TIPO_NAVEGACAO, data = dados)

# Avaliando o resultado
summary(m_multiplo)

library(dplyr)

# 1. Força o agrupamento EXCLUSIVO pelo tempo, somando todas as cargas juntas
dados_totais_mensais <- dados %>%
  group_by(tempo_continuo) %>%
  summarise(TOTAL_TONELADAS = sum(TOTAL_TONELADAS, na.rm = TRUE))

# 2. Recalcula a regressão linear simples sobre os dados consolidados
m_simples_corrigido <- lm(TOTAL_TONELADAS ~ tempo_continuo, data = dados_totais_mensais)

# 3. Gera o gráfico corrigido
par(pty = "s")
plot(dados_totais_mensais$tempo_continuo, dados_totais_mensais$TOTAL_TONELADAS,
     pch = 19, col = "blue",
     xlab = "Ano", ylab = "Toneladas Totais por Mês")

# 4. Traça a reta de tendência perfeitamente alinhada
abline(m_simples_corrigido, col = "orange", lwd = 3)
