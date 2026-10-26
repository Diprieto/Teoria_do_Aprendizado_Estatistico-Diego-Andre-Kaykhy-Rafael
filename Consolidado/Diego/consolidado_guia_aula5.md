# Consolidado — Teoria do Aprendizado Estatístico — Aula 05b (Poisson) — 2026-10-25
*guia versão 1 · tutora: Gemini · sessão única*
**Aluno:** Diego de Farias Carazo Prieto

## 1. O que foi passado
- M1 — contagens e a Poisson
- M2 — o log da média como reta; $e^{\beta}$ como razão de taxas
- M3 — glm(family = poisson) e predict(type = "response")
- M4 — o offset
- M5 — sobredispersão e quase-Poisson
- M6 — Poisson contra MQO na validação cruzada

## 2. Como foi o aprendizado — opinião da tutora
O aluno acompanhou todos os seis módulos teóricos e demonstrou excelente intuição para ordens de grandeza numéricas e cálculos mentais rápidos de $e^x$. Houve alguma hesitação inicial em propriedades teóricas fundamentais (como a igualdade entre média e variância na Poisson e a necessidade de aplicar a exponencial para converter o preditor linear na contagem esperada). O conceito de offset foi compreendido na comparação de taxas diárias, mas a fórmula de sobredispersão e a avaliação de validação cruzada precisaram de ser detalhadas passo a passo.

**Teste final:** acertou M3; a revisar M1 (variância igual à média), M2 (aplicação de $e^{-1}$ para variação percentual), M4 (valor do offset como $\log(\text{dias})$), M5 (cálculo de $\sqrt{\hat\phi}$ e impacto no erro padrão) e M6 (critérios de decisão por RMSE e restrição não negativa).

## 3. Observações para a frente
- **Revisar antes da Parte D:** reforçar as propriedades teóricas da distribuição de Poisson ($\mathbb{E}=\text{Var}=\lambda$), o cálculo do erro padrão corrigido por $\sqrt{\hat\phi}$ e a leitura do placar de validação cruzada.
- **Para a próxima tutora:** ritmo calmo com foco em reforçar os passos matemáticos antes da interpretação prática. Apoiar no manuseio das fórmulas em LaTeX.
- **Perguntas guardadas:** nenhuma.
- **Produzido nesta sessão:** placar de validação cruzada obtido: linha de base 3,99, MQO 2,39 e Poisson 1,76.
- **Parte D:** a combinar com o grupo de trabalho.