# Registro de Experimentos - Aula 9: Métodos de Suavização
**Disciplina:** Teoria do Aprendizado Estatístico — Prof. Dr. João Paulo Ferreira de Mello  
**Variáveis:** Preditor $X$ = `TOTAL_TEU` | Resposta $Y$ = `TOTAL_TONELADAS`  
**Esquema de Validação:** Validação cruzada em 5 dobras (CV-5)

---

## 1. Parâmetros Escolhidos
* **Melhor $k$ (KNN-regressão):** $k = 5$
* **Melhor $h$ (Kernel Nadaraya-Watson):** $h = 45,97$

---

## 2. Erros de Validação Cruzada (MSE)

| Modelo | Hiperparâmetro | MSE CV(5) |
| :--- | :---: | :---: |
| **Reta (MQO)** | — | **1.899.668,15** |
| **Kernel Smoothing** | $h = 45,97$ | 1.958.112,28 |
| **KNN-regressão** | $k = 5$ | 2.082.252,15 |

---

## 3. Diagnóstico e Decisão
> A relação entre volume de contêineres e peso total é essencialmente linear em toda a faixa de operação regular, apresentando desvios pontuais apenas nas caudas extremas (lotes com predominância de contêineres vazios ou de alta densidade específica); como a reta obteve o menor erro de generalização na validação cruzada ($MSE = 1.899.668,15$), **ficamos com a reta**.

---

## 4. Gráfico do Ajuste
A curva gerada com o estimador de Nadaraya-Watson ($h = 45,97$) está armazenada em `consolidados/melhor_kernel.png`.