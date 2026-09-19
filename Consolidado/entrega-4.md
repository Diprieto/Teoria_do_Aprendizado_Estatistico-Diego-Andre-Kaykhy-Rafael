# Entrega 4 — Regressão Linear

**Notebook:** `Aula4PI.ipynb` · **Linguagem:** R

---

## Objetivo

Modelar `TOTAL_TONELADAS` em função do tempo e das características da carga, medir a tendência de crescimento do volume portuário e diagnosticar os problemas do ajuste linear.

---

## 1. Leitura e tratamento

```r
dados <- readRDS("/content/exportacao_cargas.rds")

# O .rds traz as colunas numéricas como texto com vírgula decimal.
# Converte antes de usar no modelo.
dados$TOTAL_TONELADAS <- as.numeric(gsub(",", ".", dados$TOTAL_TONELADAS))
dados$TOTAL_TEU       <- as.numeric(gsub(",", ".", dados$TOTAL_TEU))
dados$TOTAL_UNID      <- as.numeric(gsub(",", ".", dados$TOTAL_UNID))

head(dados, n = 5)
```

Mesmo formato usado nas entregas 5, 6 e 7. A conversão com `gsub` é obrigatória: `lm()` com uma variável-resposta em texto retorna erro imediato.

**Amostra das primeiras linhas:**

| TOTAL_TEU | TIPO_NAVEGACAO | ANO | TERMINAIS | TOTAL_TONELADAS | NATUREZA_CARGA | SENTIDO | ANO_MES |
|---|---|---|---|---|---|---|---|
| 92 | LONGO CURSO | 2012 | SANTOS BRASIL | 1.504,855 | CONTEINERIZADA | DESEMBARQUE | 2012-11-01 |
| 28 | LONGO CURSO | 2012 | SANTOS BRASIL | 190,550 | CONTEINERIZADA | EMBARQUE | 2012-10-01 |
| 598 | CABOTAGEM | 2012 | SANTOS BRASIL | 5.631,350 | CONTEINERIZADA | DESEMBARQUE | 2012-10-01 |

---

## 2. Construção da variável temporal contínua

```r
dados$ano <- as.numeric(substr(dados$ANO_MES, 1, 4))
dados$mes <- as.numeric(substr(dados$ANO_MES, 6, 7))
dados$tempo_continuo <- dados$ano + (dados$mes - 1) / 12
```

`ANO_MES` vem como texto no formato `2012-11-01`. O `substr` extrai ano (posições 1–4) e mês (posições 6–7), e a fórmula transforma os dois em um número decimal único:

| Data | `tempo_continuo` |
|---|---|
| Janeiro/2020 | 2020,000 |
| Fevereiro/2020 | 2020,083 |
| Dezembro/2020 | 2020,917 |

**Por que isso importa:** usar `ANO` puro trataria o tempo em degraus anuais e descartaria a variação dentro do ano. Com a variável contínua, o coeficiente do modelo passa a ter leitura direta — "toneladas adicionais por ano decorrido" — e a inclinação captura a tendência real.

---

## 3. Ajuste do modelo múltiplo

```r
m_multiplo <- lm(TOTAL_TONELADAS ~ tempo_continuo + NATUREZA_CARGA + TIPO_NAVEGACAO,
                 data = dados)

summary(m_multiplo)
```

O `lm()` minimiza a soma dos quadrados dos resíduos. As variáveis categóricas são convertidas automaticamente em variáveis dummy, sempre em comparação com uma categoria de referência (a primeira em ordem alfabética).

### Resultados

```
Residuals:
   Min     1Q Median     3Q    Max
-35197  -1134   -548     -7 393703

Coefficients:
                               Estimate Std. Error t value Pr(>|t|)
(Intercept)                  -1.597e+05  1.699e+03  -94.03   <2e-16 ***
tempo_continuo                7.954e+01  8.421e-01   94.46   <2e-16 ***
NATUREZA_CARGACARGA GERAL     2.433e+03  2.833e+01   85.88   <2e-16 ***
NATUREZA_CARGAGRANEL LIQUIDO  7.916e+03  2.805e+01  282.20   <2e-16 ***
NATUREZA_CARGAGRANEL SOLIDO   3.347e+04  2.928e+01 1142.94   <2e-16 ***
TIPO_NAVEGACAOLONGO CURSO     3.092e+02  1.483e+01   20.84   <2e-16 ***

Residual standard error: 5546 on 1097008 degrees of freedom
Multiple R-squared:  0.5571,  Adjusted R-squared:  0.5571
F-statistic: 2.76e+05 on 5 and 1097008 DF,  p-value: < 2.2e-16
```

### Interpretação dos coeficientes

| Termo | Estimativa | Leitura |
|---|---|---|
| `tempo_continuo` | **+79,54** | cada ano decorrido adiciona ~80 t ao registro médio |
| `NATUREZA_CARGA` GERAL | +2.433 | vs. carga conteinerizada (referência) |
| `NATUREZA_CARGA` GRANEL LÍQUIDO | +7.916 | vs. conteinerizada |
| `NATUREZA_CARGA` GRANEL SÓLIDO | **+33.470** | maior efeito isolado da base |
| `TIPO_NAVEGACAO` LONGO CURSO | +309,2 | vs. cabotagem |

A hierarquia das cargas é o achado mais forte: **granel sólido movimenta em outra ordem de grandeza**. Um registro de granel sólido carrega, em média, 33 mil toneladas a mais que um de carga conteinerizada — mais de 400 vezes o efeito anual do tempo. A natureza da carga explica muito mais da variação do que a passagem dos anos.

### Qualidade do ajuste

- **R² = 0,5571** — o modelo explica ~55,7% da variação de `TOTAL_TONELADAS`
- **Erro padrão residual = 5.546 t**
- **F = 2,76e+05**, p < 2,2e-16 — o modelo como um todo é significativo

---

## 4. Diagnóstico dos resíduos

O bloco de resíduos é o mais revelador do `summary`:

```
   Min     1Q Median     3Q    Max
-35197  -1134   -548     -7 393703
```

A mediana (−548) e o 3º quartil (−7) são **negativos e próximos de zero**, enquanto o máximo chega a **+393.703**. Ou seja: o modelo acerta razoavelmente a maioria dos registros e erra de forma catastrófica em alguns poucos. Essa é a assinatura clássica de uma cauda longa à direita — exatamente o que a análise de outliers da Entrega 2 já havia detectado pela regra de Tukey.

---

## 5. Refinamentos aplicados

A sequência de correções documentada no notebook:

| Passo | Ação | Resultado |
|---|---|---|
| 1 | Remoção do outlier isolado que enviesava o ajuste | R² sobe de 55,71% para **55,82%** |
| 2 | Inspeção da variância dos resíduos | Heterocedasticidade confirmada — três "pilares" distintos, um por categoria de carga |
| 3 | Agregação em blocos mensais | Revela **curva em V** (relação não linear) e efeito funil |
| 4 | Transformação logarítmica | Variação explicada sobe para **mais de 70%** |
| 5 | Projeção para os anos seguintes | ~3.440.300 t em 2027 e ~3.607.202 t em 2028 |

A taxa de crescimento implícita entre 2027 e 2028 é de aproximadamente **4,7%**.

A agregação mensal do passo 3 foi necessária para reduzir a volatilidade: no nível do registro individual, o ruído é grande demais para que o padrão apareça.

> **Atenção:** apenas as conclusões dos passos 2 a 5 permanecem no notebook, nas células de markdown. O código que as gerou foi apagado. Se a entrega precisar ser reproduzida ou defendida, esses blocos precisam ser reescritos — a transformação logarítmica, em particular, é o resultado mais forte do trabalho.

---

## 6. Gráfico final — tendência consolidada

```r
library(dplyr)

# Agrupa exclusivamente pelo tempo, somando todas as cargas
dados_totais_mensais <- dados %>%
  group_by(tempo_continuo) %>%
  summarise(TOTAL_TONELADAS = sum(TOTAL_TONELADAS, na.rm = TRUE))

# Regressão simples sobre os dados consolidados
m_simples_corrigido <- lm(TOTAL_TONELADAS ~ tempo_continuo, data = dados_totais_mensais)

par(pty = "s")
plot(dados_totais_mensais$tempo_continuo, dados_totais_mensais$TOTAL_TONELADAS,
     pch = 19, col = "blue",
     xlab = "Ano", ylab = "Toneladas Totais por Mês")

abline(m_simples_corrigido, col = "orange", lwd = 3)
```

### Leitura do gráfico

**Componentes**
- **Eixo X:** tempo contínuo em anos, cobrindo todo o histórico da base
- **Eixo Y:** volume consolidado por mês, variando de ~6 milhões a mais de 14 milhões de toneladas
- **Pontos azuis:** cada ponto é a soma real da movimentação de um mês específico
- **Reta laranja:** tendência ajustada pelo modelo linear simples

**Interpretação**

*Crescimento:* a inclinação positiva comprova matematicamente o aumento contínuo e de longo prazo no volume escoado pelo complexo portuário ao longo das duas décadas.

*Heterocedasticidade:* a distância entre os pontos e a reta é estreita nos primeiros anos (2005–2010) e se expande progressivamente nos anos recentes. A variância dos resíduos cresce com o nível da série — violação direta de um dos pressupostos da regressão linear, e a razão pela qual a transformação logarítmica melhorou tanto o ajuste.

**Por que agrupar antes de plotar:** sem o `group_by`, o gráfico teria 1,1 milhão de pontos sobrepostos e a reta pareceria desalinhada da nuvem, porque o modelo múltiplo original também considera categorias. Consolidando por mês, a reta se alinha perfeitamente aos dados que ela de fato descreve.

---

## Pontos de atenção

- **Significância estatística não é relevância prática.** Com 1.097.014 observações, praticamente qualquer coeficiente sai com `p < 2e-16`. O que importa aqui é o tamanho do efeito e o R², não o p-valor.
- **Pressupostos violados.** A heterocedasticidade compromete os erros-padrão e, por consequência, os intervalos de confiança. Os coeficientes continuam sendo estimativas não enviesadas, mas a precisão declarada é otimista demais.
- **Extrapolação.** A projeção para 2027–2028 assume que a tendência linear se mantém. É uma hipótese forte para um setor sujeito a choques de demanda e câmbio.

---

## Conclusão

O modelo linear captura uma tendência real de crescimento (~80 t por ano por registro) e mostra que a natureza da carga é de longe o fator mais determinante do volume. Com R² de 55,7%, o ajuste é razoável, mas os diagnósticos deixam claro que a relação não é puramente linear: a transformação logarítmica levou a variação explicada para mais de 70%.

Essa entrega estabelece o modelo; as entregas 6 e 7 verificam se ele de fato generaliza para dados não vistos.
