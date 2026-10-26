# Consolidado — Teoria do Aprendizado Estatístico — Aula 05b (Poisson) — 2026-10-25
*guia versão 1 · tutora: Perplexity · sessão única*
**Andre Cesar Franco** —
## 1. O que foi passado
- M1 — contagens e a Poisson
- M2 — o log da média como reta; $e^{\beta}$ como razão de taxas
- M3 — glm(family = poisson) e predict(type = "response")
- M4 — o offset
- M5 — sobredispersão e quase-Poisson
- M6 — Poisson contra MQO na validação cruzada
## 2. Como foi o aprendizado — opinião da tutora
Você construiu bem a leitura dos coeficientes, a conversão do log para visitas com $e^{(\cdot)}$ e o cálculo de taxas com o offset. Precisou de apoio nas operações com $e^x$ e $\log$, e no Módulo 5 não chegou sozinho ao erro padrão corrigido. O placar de validação foi interpretado corretamente.
**Teste final:** acertou M1, M2, M3, M4 e M6; a revisar M5 — aplicar $\sqrt{\hat\phi}$ ao erro padrão e recalcular $|z|$.
## 3. Observações para a frente
- **Revisar antes da Parte D:** sobredispersão, $\hat\phi$, erro padrão corrigido e $|z|$.
- **Para a próxima tutora:** começar com exemplos numéricos de $e^x$ e $\log$; ritmo mais devagar nas contas.
- **Perguntas guardadas:** nenhuma registrada.
- **Produzido nesta sessão:** placar de validação cruzada: média $3{,}99$; MQO $2{,}39$; Poisson $1{,}76$.
- **Parte D:** não combinada.