# Guia Consolidado: Regressão de Poisson no R

## 1. A Matemática do Modelo (O Link Log)
O modelo de Poisson garante que a previsão seja sempre positiva, aplicando a função logarítmica para conectar os preditores à variável resposta.

* **A Equação:** $\log(\lambda) = \beta_0 + \beta_1x$
* **A Previsão:** Para achar a contagem esperada ($\lambda$), aplicamos a exponencial: $\lambda = e^{\beta_0 + \beta_1x}$
* **Interpretação dos Coeficientes:** Um aumento de $1$ unidade em $x$ multiplica a contagem esperada por $e^{\beta_1}$.

## 2. Sintaxe Básica e Previsão
No R, a regressão de Poisson é feita via Modelos Lineares Generalizados (`glm`).

```R
# Ajuste do modelo
modelo <- glm(Y ~ X1 + X2, family = poisson, data = base)

# Previsão CORRETA (retorna a contagem esperada)
predict(modelo, newdata = nova_base, type = "response")

# Previsão ERRADA (retorna o valor na escala logarítmica)
predict(modelo, newdata = nova_base) 
```

## 3. Exposição Variável (Offset)
Usado quando as observações acontecem em janelas de tempo diferentes (ex: meses de 28, 30 ou 31 dias). Ele transforma o modelo para prever a **taxa** de eventos por unidade de tempo, sem estimar um coeficiente para o tempo.

* **Regra de ouro:** O tempo precisa entrar obrigatoriamente dentro de um logaritmo.

```R
# O offset entra direto na fórmula somando
modelo_taxa <- glm(Y ~ X1 + offset(log(dias)), family = poisson, data = base)
```

## 4. Sobredispersão (Quasi-Poisson)
A regressão de Poisson assume que a média é igual à variância. Quando os dados reais variam muito mais que a média, temos sobredispersão ($\hat\phi > 1$). Ignorar isso faz você acreditar em coeficientes que não são estatisticamente significativos (erros padrão ficam baixos demais).

* **Cálculo da dispersão ($\hat\phi$):**
```R
phi <- sum(residuals(modelo, type = "pearson")^2) / df.residual(modelo)
```

* **A Correção:** Mudar a família para `quasipoisson`. Os coeficientes ($\beta$) continuam idênticos, mas o R multiplica os Erros Padrão por $\sqrt{\hat\phi}$, corrigindo o excesso de confiança e reduzindo os valores de $\lvert z\rvert$.
```R
modelo_corrigido <- glm(Y ~ X1, family = quasipoisson, data = base)
```

## 5. Poisson vs. MQO (Validação Cruzada)
Para justificar o uso da Poisson, comparamos o erro preditivo (RMSE) fora da amostra com o da Regressão Linear tradicional (MQO).

* **O Perigo do MQO:** A regressão linear traça uma reta. Se a tendência cair muito, a reta cruza o eixo zero e passa a prever **contagens negativas** (matematicamente impossíveis na vida real).
* **A Vantagem da Poisson:** Acompanha a curva multiplicativa dos dados de contagem, respeita o limite do zero absoluto e costuma entregar um RMSE sistematicamente menor na validação cruzada.