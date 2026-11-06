# Entrega Aula 11 - Árvores de Decisão e Random Forest
**Aluno:** Diego de Farias Carazo Prieto  
**Disciplina:** Teoria do Aprendizado Estatístico — Fatec Baixada Santista  
**Base:** Exportação de Cargas do Porto de Santos (1º Trimestre de 2017 a 2026)

---

## 1. Placar Comparativo de Modelos

| Método | Configuração / Hiperparâmetro | Validação (MSE) | RMSE de Validação (toneladas) |
| :--- | :--- | :---: | :---: |
| **Linha de Base** | Prever a média | 88.336.313 | 9.398,74 |
| **MQO Linear (Aula 4)** | Termos lineares | 30.162.283 | 5.492,02 |
| **GAM com Splines (Aula 10)** | $s(\text{tempo}) + s(\text{TOTAL\_TEU})$ | 30.144.272 | 5.490,38 |
| **Árvore Podada (Aula 11)** | 8 folhas ($cp = 0,00189$) | 65.647.399 | 8.102,31 |
| **Random Forest (Aula 11)** | $mtry = 2$, $B = 500$ árvores (OOB) | 68.157.919 | 8.255,78 |

---

## 2. Perguntas Conceituais e Diagnóstico do Laboratório

### 2.1. Primeira pergunta da árvore e detecção de interações
* **Raiz da árvore:** A primeira pergunta divide a base pelo preditor `teu` (ex.: `teu < 14.5` ou `natureza = Carga Conteinerizada`), separando operações que operam em escala unitizada daquelas voltadas a granéis ou cargas soltas.
* **Interações detectadas:** A árvore identifica interações automáticas: após o corte inicial de volume/natureza, os ramos bifurcam avaliando o tipo de navegação (Longo Curso vs. Cabotagem) e a trajetória temporal de maneira assimétrica. O efeito da navegação só se manifesta em determinados patamares de volume, demonstrando a capacidade do CART de particionar o espaço sem imposição prévia de termos aditivos.

### 2.2. Importância dos Preditores (Random Forest)
* Conforme gerado pelo `varImpPlot()` via aumento do erro fora do saco (OOB):
  1. **`teu` (TOTAL_TEU):** Preditor com maior acréscimo de MSE ao ser embaralhado, demonstrando dependência direta da tonelagem em relação ao volume de contêineres.
  2. **`natureza` (NATUREZA_CARGA):** Segundo preditor mais relevante, discriminando perfis de peso específico (granéis sólidos vs. carga conteinerizada).
  3. **`tempo` e `navegacao`:** Impacto secundário e estabilizador na variância do conjunto.

### 2.3. O que isso muda ou indica para a pergunta de pesquisa?
* **Derrota dos modelos baseados em árvore frente ao GAM e MQO:** Tanto a árvore podada (RMSE 8.102,31) quanto a Random Forest (RMSE 8.255,78) apresentaram erro substancialmente superior ao GAM (5.490,38) e ao MQO (5.492,02).
* **Fundamento estatístico:** Árvores aproximam a resposta por funções em degraus (médias locais em hiper-retângulos). Como a relação entre a quantidade de contêineres/tempo e o peso movimentado no Porto de Santos é dominantemente suave, contínua e linear ($y \approx \beta \cdot \text{TEU}$), os degraus das 8 folhas introduzem viés elevado. Conforme demonstrado na teoria da aula, quando a verdade geradora dos dados é aditiva e linear, modelos aditivos generalizados e MQO superam árvores de decisão.
* **Conclusão prática:** Não há evidência de interações locais fortes o bastante que justifiquem trocar a precisão e a interpretabilidade do modelo GAM/MQO por uma floresta aleatória neste problema de previsão de tonelagem portuária.

---

## 3. Figuras Geradas

* `figuras/aula11_arvore_podada.png`: Topologia dos primeiros 3 níveis da árvore podada (`maxdepth = 3`).
* `figuras/aula11_importancia_preditores.png`: Gráfico de importância dos preditores via permutação OOB.