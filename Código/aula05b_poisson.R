# ==============================================================================
# Teoria do Aprendizado Estatistico - Aula 05b: Regressao de Poisson (Parte D)
# Grupo: Predicarga
# Integrantes: Andre Franco, Diego Prieto, Kaykhy Donizete, Rafael Pinto
# ==============================================================================

# ------------------------------------------------------------------------------
# Leitura e Inspecao Inicial dos Dados
# ------------------------------------------------------------------------------
# Le o arquivo original do Porto de Santos garantindo compatibilidade de codificacao
dados <- read.csv("dados_porto_santos.csv", fileEncoding = "UTF-8-BOM")

# Inspeciona as dimensoes e tipos das colunas
str(dados)

# Confere o numero total de registros historicos
nrow(dados)

# ------------------------------------------------------------------------------
# Modulo 7: Construcao da Variavel de Contagem (Terminal x Mes)
# ------------------------------------------------------------------------------
# Agrega o numero de operacoes por Terminal e Ano/Mes, preservando combinacoes com zero
cont <- as.data.frame(table(dados$TERMINAIS, dados$ANO_MES))

# Renomeia as colunas para facilitar a manipulacao
names(cont) <- c("terminal", "ano_mes", "n")

# Confere quantas combinacoes tiveram zero operacoes
sum(cont$n == 0)

# Resumo estatistico da contagem gerada
summary(cont$n)

# Confere o numero total de linhas da base de contagem
nrow(cont)

# ------------------------------------------------------------------------------
# Modulo 8: Ajuste do Modelo de Poisson e Diagnostico de Dispersao
# ------------------------------------------------------------------------------
# Extrai o mes do calendario a partir de ano_mes para capturar sazonalidade
cont$mes <- as.factor(format(as.Date(cont$ano_mes), "%m"))

# Converte o terminal em fator para estimar os efeitos por berco/empresa
cont$terminal <- as.factor(cont$terminal)

# Ajusta o modelo linear generalizado com distribuicao de Poisson
m <- glm(n ~ terminal + mes, family = poisson, data = cont)

# Calcula os primeiros coeficientes exponenciados (razoes de taxas multiplicativas)
round(exp(coef(m))[1:6], 3)

# Calcula o parametro de dispersao estimado phi_hat
phi_hat <- sum(residuals(m, type = "pearson")^2) / df.residual(m)
phi_hat

# Exibe sumario dos coeficientes e erros padrao
summary(m)$coefficients[1:6, ]

# ------------------------------------------------------------------------------
# Modulo 9: Validacao Cruzada (5 Dobras) e Comparacao de Modelos
# ------------------------------------------------------------------------------
# Fixa a semente para garantir reprodutibilidade das mesmas dobras
set.seed(1)

# Sorteia as 5 dobras para avaliacao imparcial
dobra <- sample(rep(1:5, length.out = nrow(cont)))

# Funcao para calcular o RMSE medio atraves de 5-fold cross validation
rmse_cv <- function(ajusta) {
  sqrt(mean(sapply(1:5, function(j) {
    tr <- cont[dobra != j, ]
    va <- cont[dobra == j, ]
    mean((va$n - ajusta(tr, va))^2)
  })))
}

# 1. Linha de base: previsao ingenua pela media global do treino
rmse_base <- rmse_cv(function(tr, va) rep(mean(tr$n), nrow(va)))

# 2. Modelo Linear Classico: Minimos Quadrados Ordinarios (MQO)
rmse_mqo <- rmse_cv(function(tr, va) predict(lm(n ~ terminal + mes, data = tr), va))

# 3. Regressao de Poisson: previsao na escala da contagem esperada
rmse_poi <- rmse_cv(function(tr, va) predict(glm(n ~ terminal + mes, family = poisson, data = tr), va, type = "response"))

# Placar comparativo consolidado
placar <- c(Linha_de_Base = rmse_base, MQO = rmse_mqo, Poisson = rmse_poi)
round(placar, 2)
