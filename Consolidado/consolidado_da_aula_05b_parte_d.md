# Consolidado — Teoria do Aprendizado Estatístico — Aula 05b — Parte D — 2026-10-25
*guia versão 1 · tutora: Gemini · sessão de grupo*
**Grupo:** Predicarga · **presentes:** Diego de Farias Carazo Prieto · **digitou:** Diego (M7, M8 e M9)

## 1. O que foi feito
- M7 — a contagem: agregação de operações por par terminal $\times$ mês (`terminal x ano_mes`), gerando $18.576$ linhas e $6.522$ combinações com contagem zero; sem variação crítica de exposição (sem offset)
- M8 — o modelo: preditores `terminal` e `mes` (sazonalidade); $\hat\phi = 38{,}49$ (forte sobredispersão, indicando quase-Poisson para fins de inferência estatística)
- M9 — o placar: linha de base $\text{RMSE} = 245{,}47$, MQO $\text{RMSE} = 117{,}02$, Poisson $\text{RMSE} = 117{,}27$; decisão: empate técnico em métrica de teste, com preferência ao Poisson por coerência lógica (previsões estritamente não negativas)

## 2. Como o grupo trabalhou — opinião da tutora
A sessão de grupo transcorreu de forma ágil e focada, conduzida pelo Diego em nome da equipe Predicarga. A adaptação da base portuária para contagens de operações operou no Caso 2 com preservação integral dos zeros. Os blocos de código foram executados sem erros de sintaxe ou de memória. As respostas de interpretação do modelo multiplicativo e do diagnóstico de superdispersão foram fixadas com clareza. A decisão no Módulo 9 considerou o critério estatístico sem perder de vista a viabilidade prática da operação no Porto de Santos.

**Verificação final:** acertou M7, M8 e M9.

## 3. Observações para a frente
- **Para o trabalho:** A contagem de atracações/operações por mês pode servir como pergunta auxiliar de planejamento operacional de berços, mantendo a pergunta principal em toneladas para a modelagem supervisionada completa da Entrega 2.
- **Perguntas guardadas:** Nenhuma pergunta pendente.
- **Produzido:** o código em `estrutura/codigo/aula05b_poisson.R` e o placar acima.