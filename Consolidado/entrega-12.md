# Relatório de Consolidação — Aula 12
**Disciplina:** Teoria do Aprendizado Estatístico  
**Tema:** Agrupamento ($K$-médias) e Análise de Componentes Principais (PCA)  
**Base de Dados:** `exportacao_cargas_1trimestre_2017_2026` (Porto de Santos)  

---

## 1. Análise de Componentes Principais (PCA)

A padronização das variáveis foi aplicada previamente ($\mu = 0, \sigma = 1$), garantindo que a escala de grandeza das unidades ou do ano não dominasse a variância em relação aos contêineres ($TEU$).

### Variância Explicada

| Componente | Fração da Variância | Variância Acumulada |
| :--- | :---: | :---: |
| **PC1** | $0{,}336$ ($33{,}6\%$) | $33{,}6\%$ |
| **PC2** | $0{,}333$ ($33{,}3\%$) | $66{,}9\%$ |
| **PC3** | $0{,}331$ ($33{,}1\%$) | $100{,}0\%$ |

As três primeiras dimensões distribuem a variância de maneira balanceada (~$33\%$ cada). Juntas, a **PC1** e a **PC2** explicam **$66{,}9\%$** de toda a variabilidade presente no conjunto de preditores operacionais.

### Pesos das Componentes (Loadings / Rotation)

| Variável | PC1 | PC2 |
| :--- | :---: | :---: |
| `teu` | $+0{,}352$ | $+0{,}935$ |
| `unid` | $+0{,}665$ | $-0{,}225$ |
| `tempo` | $-0{,}658$ | $+0{,}273$ |

### Interpretação e Nomenclatura das Componentes

* **PC1 — Escala Unitária vs. Histórico:**  
  Apresenta carga fortemente positiva em `unid` ($+0{,}665$) e moderada em `teu` ($+0{,}352$), contrastando com o sinal negativo em `tempo` ($-0{,}658$). Essa régua discrimina despachos de grande contagem de volumes físicos concentrados nas janelas operacionais mais antigas da série.
* **PC2 — Intensidade de Conteinerização ($TEU$):**  
  Dominada quase que com exclusividade pelo peso em `teu` ($+0{,}935$), tendo influência secundária de `tempo` ($+0{,}273$) e peso inverso em `unid` ($-0{,}225$). Opera como a régua direta do volume conteinerizado por registro aduaneiro.

---

## 2. Seleção do Número de Grupos ($K$) e Silhueta Média

Para evitar a subjetividade do método do cotovelo, utilizou-se o coeficiente de silhueta média calculado para $K \in [2, 8]$ sobre as distâncias euclidianas padronizadas ($Z$):

| $K$ (Grupos) | Silhueta Média | Diagnóstico |
| :---: | :---: | :--- |
| $K=2$ | $0{,}497$ | Separação inicial razoável |
| $K=3$ | $0{,}551$ | Boa coesão interna |
| **$K=4$** | **$0{,}566$** | **Pico máximo de coesão e separação** |
| $K=5$ | $0{,}491$ | Queda brusca (sobre-segmentação) |
| $K=6$ | $0{,}504$ | Estabilização |
| $K=7$ | $0{,}510$ | Sem ganho expressivo |
| $K=8$ | $0{,}492$ | Fragmentação excessiva |

**Conclusão:** O critério formal da silhueta máxima estabelece **$K = 4$** como o número ótimo de agrupamentos.

---

## 3. Centros dos Grupos nas Unidades Originais e Interpretação

Com $K=4$, as médias das variáveis em escala real em cada agrupamento revelam perfis operacionais claros:

| Grupo | `teu` Médio | `unid` Média | `tempo` Médio (Ano) | Perfil / Nome do Grupo |
| :---: | :---: | :---: | :---: | :--- |
| **1** | $814{,}15$ | $462{,}62$ | $2021{,}70$ | **Conteinerizado Regular de Médio/Grande Porte** |
| **2** | $40{,}77$ | $132{,}82$ | $2024{,}12$ | **Fracionado / Pequeno Porte Recente** |
| **3** | $42{,}68$ | $134{,}18$ | $2019{,}11$ | **Fracionado / Pequeno Porte Histórico** |
| **4** | $2.154{,}00$ | $36.962{,}08$ | $2021{,}21$ | **Mega-Operações / Lotes Massivos** |

### Descrição dos Perfis:
1. **Grupo 1 (Conteinerizado Regular):** Embarques padrão de linhas regulares de navegação, com expressivo volume de contêineres ($814$ TEUs) e unidades proporcionais.
2. **Grupo 2 (Fracionado Recente):** Operações concentradas entre 2023 e 2026 com baixo volume unitário e poucos contêineres por lote.
3. **Grupo 3 (Fracionado Histórico):** Idêntica escala física ao Grupo 2, porém situado no início do horizonte temporal analisado (média em 2019).
4. **Grupo 4 (Mega-Operações):** Movimentações de porte excepcional, com quase 37 mil unidades e mais de 2.150 TEUs, correspondendo a grandes navios porta-contêineres ou consolidações atípicas.

---

## 4. Visualizações Gráficas

As visualizações foram geradas e gravadas no arquivo `aula12_graficos.png`:
* **Painel 1 (Plano PC1 vs. PC2):** Projeta as observações nos dois eixos principais com a coloração dos 4 grupos do $K$-médias, comprovando que os grupos ocupam regiões bem definidas do espaço vetorial.
* **Painel 2 (Boxplot de Resposta):** Mostra a dispersão e mediana da variável resposta ($Y = \text{TOTAL\_TONELADAS}$) segmentada por cluster.

![Gráficos da Aula 12](aula12_graficos.png)

---

## 5. Impacto na Pergunta de Negócio ($Y = \text{TOTAL\_TONELADAS}$)

### A resposta varia de um grupo para o outro?
**Sim, substancialmente.** A variável resposta (tonelagem total exportada) acompanha o salto de escala identificado nos centros dos clusters:
* Os Grupos 2 e 3 concentram distribuições de tonelagem reduzidas e homogêneas.
* O Grupo 1 exibe medianas de tonelagem intermediárias e condizentes com tráfego conteinerizado constante.
* O Grupo 4 apresenta ordens de grandeza muito superiores em tonelagem, concentrando valores que antes apareciam como assimetrias ou desvios em modelos globais.

### O grupo vira preditor?
**Sim, e com grande ganho preditivo:**
1. **Como preditor categórico (fator de 4 níveis):** A variável de agrupamento pode ser inserida diretamente em modelos de regressão múltipla, árvores de decisão ou GAMs. Ela permite que o modelo adote interceptos específicos para cada regime operacional, controlando a heterogeneidade da base de dados.
2. **Uso das componentes (PC1 e PC2):** As componentes principais eliminam a multicolinearidade entre contêineres (`teu`) e unidades físicas (`unid`), retendo dois terços da variância original em regressores ortogonais ($r=0$).
3. **Estratificação:** O agrupamento sugere que pode ser vantajoso ajustar modelos de predição separados para os registros de grande lote (Grupo 4) em relação aos fluxos fracionados (Grupos 2 e 3).