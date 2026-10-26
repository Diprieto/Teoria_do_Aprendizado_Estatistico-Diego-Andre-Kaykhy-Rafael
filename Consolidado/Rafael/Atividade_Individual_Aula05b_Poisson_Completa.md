# Aula 05b --- Regressão de Poisson

## Atividade individual --- consolidado teórico

**Aluno:** Rafael de Sousa Rodrigues Pinto\
**Disciplina:** Teoria do Aprendizado Estatístico\
**Guia:** Aula 05b --- Regressão de Poisson, versão 1

> Observação: este documento organiza as respostas dos seis módulos
> individuais do guia fornecido. Os resultados numéricos abaixo são os
> informados no próprio guia. Para comprovar a execução prática, é
> necessário rodar os códigos no R e conferir as saídas.

## 1. Conceitos iniciais

Uma variável de contagem representa o número de ocorrências de um evento
em determinado intervalo de tempo ou espaço. Seus valores são inteiros
não negativos: 0, 1, 2, 3 etc. Exemplos são visitas a um anúncio por mês
e ligações recebidas por dia. A regressão de Poisson é adequada para
respostas desse tipo. A regressão logística, por sua vez, modela a
probabilidade de um evento com duas possibilidades, como pagar ou não
pagar um empréstimo.

Lembretes matemáticos: (e\^0=1) e (`\log`{=tex}(1)=0). A exponencial e o
logaritmo natural são operações inversas. O comando
`glm(..., family = binomial)` ajusta um modelo de regressão logística
por máxima verossimilhança.

## Módulo 1 --- Contagens: por que a reta não serve

Uma contagem nunca é negativa e assume apenas valores inteiros. A
regressão linear ajustada por mínimos quadrados ordinários (MQO) pode
produzir previsões negativas, que não fazem sentido para uma quantidade
de ocorrências. No exemplo de oito anúncios do guia, a reta prevê −0,73
visitas a 4,5 km e −1,66 visitas a 5 km, embora a contagem observada a
4,5 km seja zero.

A distribuição de Poisson é definida por:

\[ P(Y=k)=`\frac{e^{-\lambda}\lambda^k}{k!}`{=tex},
`\qquad `{=tex}`\mathbb{E}`{=tex}\[Y\]=`\operatorname{Var}`{=tex}(Y)=`\lambda`{=tex}.
\]

Isso significa que, no modelo de Poisson, a média e a variância são
iguais. Quando a média esperada aumenta, a variabilidade também aumenta.

**Checkpoint 1 --- resposta:**\
Se um corretor recebe em média 4 ligações por dia, a probabilidade de
não receber nenhuma é (P(Y=0)=e\^{-4}`\approx0{,}`{=tex}0183), ou
aproximadamente 1,83%. A variância do número de ligações é igual à
média: 4.

## Módulo 2 --- O modelo: o log da média é uma reta

A regressão de Poisson modela o logaritmo da média esperada como uma
combinação linear dos preditores:

\[
`\log`{=tex}`\lambda`{=tex}=`\beta`{=tex}\_0+`\beta`{=tex}\_1x_1+`\dots`{=tex}+`\beta`{=tex}\_px_p
`\quad`{=tex}`\Longleftrightarrow`{=tex}`\quad`{=tex}
`\lambda`{=tex}=e\^{`\beta`{=tex}\_0+`\beta`{=tex}\_1x_1+`\dots`{=tex}+`\beta`{=tex}\_px_p}.
\]

Como uma exponencial é sempre positiva, a média prevista não fica
negativa. Um aumento de uma unidade em um preditor multiplica a média
esperada por (e\^`\beta`{=tex}). A variação percentual é
((e\^`\beta-1`{=tex})`\times100`{=tex}%). Assim, o coeficiente não deve
ser interpretado como uma quantidade fixa de visitas somadas ou
subtraídas.

No exemplo (`\log`{=tex}`\lambda=2`{=tex}-0{,}5x), as médias aproximadas
são 7,39 visitas quando (x=0), 4,48 quando (x=1) e 2,72 quando (x=2). A
razão por quilômetro é (e\^{-0{,}5}`\approx0{,}`{=tex}607).

**Checkpoint 2 --- resposta:**\
Para (`\log`{=tex}`\lambda=1`{=tex}+0{,}3x), com (x) igual ao número de
quartos: para 0 quartos, (`\lambda`{=tex}=e\^1`\approx2{,}`{=tex}72);
para 2 quartos, (`\lambda`{=tex}=e\^{1{,}6}`\approx4{,}`{=tex}95). Por
quarto, a média é multiplicada por (e\^{0{,}3}`\approx1{,}`{=tex}35), ou
seja, aumenta cerca de 35%.

## Módulo 3 --- Ajustar e ler no R

A base `anuncios` contém 200 anúncios, observados por 30 dias, com
distância até a praia (`dist`), número de fotos (`fotos`) e visitas
observadas (`visitas`). O modelo é ajustado com `glm()` e
`family = poisson`.

``` r
m <- glm(visitas ~ dist + fotos, family = poisson, data = anuncios)  # ajusta a regressao de Poisson
round(coef(m), 4)                                                    # coeficientes na escala do log
round(exp(coef(m)), 4)                                               # multiplicadores dos coeficientes
novo <- data.frame(dist = 1, fotos = 12)                             # anuncio a 1 km, com 12 fotos
predict(m, novo)                                                     # retorna o log da media prevista
predict(m, novo, type = "response")                                  # retorna visitas esperadas
```

O guia informa coeficientes estimados aproximados de 1,5738 para o
intercepto, −0,5217 para distância e 0,0653 para fotos. Após aplicar
`exp()`, os multiplicadores são 4,8248, 0,5935 e 1,0674. Mantendo as
fotos fixas, cada quilômetro adicional multiplica as visitas esperadas
por 0,594, uma redução aproximada de 41%. Mantendo a distância fixa,
cada foto adicional multiplica as visitas esperadas por 1,067, um
aumento de 6,7%.

Para um anúncio a 1 km com 12 fotos, o guia informa previsão de 6,27
visitas em 30 dias (valor verdadeiro da simulação: 6,17). É importante
usar `type = "response"`: sem esse argumento, `predict()` retorna o log
da média prevista, não a contagem esperada.

**Checkpoint 3 --- resposta:**\
Para 3 km e 5 fotos, o preditor linear é
(1{,}5738-0{,}5217`\times3`{=tex}+0{,}0653`\times5`{=tex}=0{,}3352).
Logo, a média prevista é (e\^{0{,}3352}`\approx1{,}`{=tex}40) visitas em
30 dias.

## Módulo 4 --- Tempo de exposição: o offset

Quando os anúncios ficam tempos diferentes no ar, comparar apenas o
total de visitas pode ser enganoso. É necessário comparar a taxa por
dia. No exemplo, o anúncio A tem 6 visitas em 30 dias (0,2 visita por
dia), enquanto o anúncio B tem 4 visitas em 10 dias (0,4 visita por
dia); portanto, B é mais procurado por dia.

O *offset* incorpora o tempo de exposição com coeficiente fixo igual a
1:

\[
`\lambda`{=tex}\_i=`\text{dias}`{=tex}\_i`\cdot `{=tex}e\^{`\beta`{=tex}\_0+`\beta`{=tex}\_1x_i}
`\quad`{=tex}`\Longleftrightarrow`{=tex}`\quad`{=tex}
`\log`{=tex}`\lambda`{=tex}\_i=`\log`{=tex}(`\text{dias}`{=tex}\_i)+`\beta`{=tex}\_0+`\beta`{=tex}\_1x_i.
\]

No R, usa-se `offset(log(dias))`.

``` r
sem <- glm(visitas ~ dist + fotos, family = poisson, data = an2)  # ignora os dias no ar
com <- glm(visitas ~ dist + fotos + offset(log(dias)),            # inclui a exposicao
           family = poisson, data = an2)                          # mesma familia Poisson
round(exp(coef(sem)), 3)                                           # multiplicadores sem offset
round(exp(coef(com)), 3)                                           # multiplicadores com offset
predict(com, data.frame(dist = 1, fotos = 12, dias = 20),
        type = "response")                                         # previsao para 20 dias
```

Segundo o guia, sem *offset* a distância parece reduzir as visitas em
17% por quilômetro; com *offset*, a redução é de 38%, próxima da verdade
simulada de 39%. O modelo com *offset* prevê aproximadamente 3,85
visitas para um anúncio a 1 km, com 12 fotos, durante 20 dias.

**Checkpoint 4 --- resposta:**\
O anúncio C teve 9 visitas em 45 dias: (9/45=0{,}2) visita por dia. O
anúncio D teve 5 visitas em 10 dias: (5/10=0{,}5) visita por dia.
Portanto, D é mais procurado por dia. Se a taxa prevista é 0,3 visita
por dia durante 12 dias, esperamos (0{,}3`\times12`{=tex}=3{,}6)
visitas.

## Módulo 5 --- Sobredispersão

A Poisson supõe que a variância condicional seja igual à média. Quando a
variância observada é maior, há sobredispersão. Ela pode surgir porque
existem diferenças entre observações que os preditores não capturam.

O guia usa o resíduo de Pearson:

\[ r_i=`\frac{y_i-\hat{\lambda}_i}{\sqrt{\hat{\lambda}_i}}`{=tex},
`\qquad`{=tex} `\hat{\phi}`{=tex}=`\frac{\sum r_i^2}{n-p}`{=tex}. \]

Na Poisson, espera-se (`\hat{\phi}`{=tex}) próximo de 1. Quando há
sobredispersão, a quase-Poisson mantém os coeficientes, mas ajusta os
erros padrão.

``` r
mp <- glm(visitas_od ~ dist + fotos, family = poisson, data = anuncios)  # Poisson
sum(residuals(mp, type = "pearson")^2) / df.residual(mp)                  # estimativa de phi
mq <- glm(visitas_od ~ dist + fotos, family = quasipoisson, data = anuncios) # quase-Poisson
round(cbind(coef(mp), coef(mq)), 4)                                       # compara coeficientes
round(cbind(summary(mp)$coefficients[, 2],
            summary(mq)$coefficients[, 2]), 4)                            # compara erros padrao
```

O guia informa (`\hat{\phi}`{=tex}=0{,}91) para `visitas` e
(`\hat{\phi}`{=tex}=3{,}37) para `visitas_od`. Na base mais dispersa, os
coeficientes não mudam; o erro padrão da distância aumenta de 0,0303
para 0,0556, aproximadamente por um fator de 1,84.

**Checkpoint 5 --- resposta:**\
Com (`\hat{\phi}`{=tex}=2{,}25), o fator de correção é
(`\sqrt{2{,}25}`{=tex}=1{,}5). O erro padrão corrigido é
(0{,}05`\times1{,}`{=tex}5=0{,}075). O valor absoluto da estatística cai
de (0{,}12/0{,}05=2{,}4) para (0{,}12/0{,}075=1{,}6); portanto, deixa de
ser maior que 2.

## Módulo 6 --- Fora da amostra: Poisson contra MQO

A validação cruzada divide os dados em cinco partes (dobras). Em cada
rodada, quatro partes são usadas para treino e uma para validação. O
RMSE (*raiz do erro quadrático médio*) resume o erro de previsão na
unidade da resposta: neste caso, visitas. Os modelos devem ser
comparados nas mesmas dobras.

``` r
set.seed(1); dobra <- sample(rep(1:5, length = n))  # cria as cinco dobras
rmse_cv <- function(ajusta) sqrt(mean(sapply(1:5, function(j) {
  tr <- anuncios[dobra != j, ]; va <- anuncios[dobra == j, ]
  mean((va$visitas - ajusta(tr, va))^2)
})))
rmse_cv(function(tr, va) rep(mean(tr$visitas), nrow(va)))
rmse_cv(function(tr, va) predict(lm(visitas ~ dist + fotos, data = tr), va))
rmse_cv(function(tr, va) predict(glm(visitas ~ dist + fotos, family = poisson,
                                     data = tr), va, type = "response"))
```

Os resultados informados no guia são: previsão pela média, RMSE = 3,99;
MQO, RMSE = 2,39; Poisson, RMSE = 1,76. O Poisson tem o menor erro de
validação. Além disso, o MQO gerou previsões negativas para 23 anúncios
na validação, enquanto a média prevista pelo Poisson é positiva.

**Checkpoint 6 --- resposta:**\
A regressão de Poisson garante uma média prevista positiva porque
(`\hat{\lambda}`{=tex}=e\^`\eta`{=tex}), e a exponencial é sempre maior
que zero. O MQO não oferece essa garantia e pode prever contagens
negativas, como −3,38 visitas no exemplo.

## 2. Teste final --- respostas

1.  **Módulo 1:** Para média de 0,5 proposta por dia,
    (P(Y=0)=e\^{-0{,}5}`\approx0{,}`{=tex}607). A variância é 0,5.
2.  **Módulo 2:** Com (`\beta=-0{,}`{=tex}1) por ano, um imóvel 10 anos
    mais velho multiplica as visitas esperadas por
    (e\^{-1}`\approx0{,}`{=tex}368), uma queda de aproximadamente 63%.
3.  **Módulo 3:** Se `predict()` retorna 2,3 sem `type = "response"`,
    esse valor está na escala do log. A previsão é
    (e\^{2{,}3}`\approx9{,}`{=tex}97), aproximadamente 10 visitas.
4.  **Módulo 4:** Para 15 dias e taxa de 0,4 visita por dia, esperamos
    (0{,}4`\times15`{=tex}=6) visitas. O *offset* é
    (`\log`{=tex}(15)`\approx2{,}`{=tex}71).
5.  **Módulo 5:** Com (`\hat{\phi}`{=tex}=4), o fator é
    (`\sqrt{4}`{=tex}=2). O erro padrão corrigido é
    (0{,}10`\times2`{=tex}=0{,}20). O valor absoluto de (z) cai de
    (0{,}30/0{,}10=3) para (0{,}30/0{,}20=1{,}5).
6.  **Módulo 6:** Escolheria Poisson, pois apresenta o menor RMSE de
    validação (3,2), contra 3,9 para MQO e 5,1 para a média. Também não
    prevê contagens negativas.

## 3. Conclusão

A regressão de Poisson é indicada para respostas de contagem. Ela modela
o log da média esperada como uma função linear dos preditores,
garantindo previsões positivas e permitindo interpretar os coeficientes
como efeitos multiplicativos. O *offset* ajusta diferenças no tempo de
exposição. A sobredispersão é verificada comparando a dispersão de
Pearson com 1; quando ela é relevante, a quase-Poisson corrige os erros
padrão. A escolha do modelo deve considerar a validação fora da amostra.
Nos resultados do guia, Poisson teve RMSE 1,76, melhor que MQO (2,39) e
que a previsão pela média (3,99).

## 4. Consolidado da sessão

-   **Conteúdo passado:** módulos 1 a 6 --- contagens e Poisson; log da
    média como reta e (e\^`\beta`{=tex}) como razão de taxas;
    `glm(family = poisson)` e `predict(type = "response")`; *offset*;
    sobredispersão e quase-Poisson; comparação entre Poisson e MQO por
    validação cruzada.
-   **Como foi o aprendizado:** as respostas dos checkpoints e do teste
    final foram entregues com ajuda da tutora, em vez de serem
    construídas de forma independente. Recomenda-se revisar
    especialmente a interpretação de (e\^`\beta`{=tex}), a diferença
    entre log da média e média prevista, o *offset* e a correção dos
    erros padrão por sobredispersão.
-   **Revisar antes da Parte D:** conferir os conceitos e executar os
    códigos no R, especialmente o ajuste do modelo e a validação
    cruzada.
-   **Para a próxima tutora:** explicar em blocos curtos, comentar os
    códigos e conferir os resultados sem inventar números fora do guia.
-   **Perguntas guardadas:** nenhuma registrada.
-   **Produzido nesta sessão:** respostas dos seis checkpoints,
    respostas do teste final e registro dos resultados de validação
    cruzada informados no guia: 3,99 / 2,39 / 1,76.
-   **Parte D:** ainda não realizada; exige o banco de dados e a ficha
    da pergunta da Entrega 1 do grupo.

## 5. Próxima etapa

A Parte D é a atividade prática em grupo. Nela, o grupo deve procurar
uma variável de contagem no próprio banco (ou criar uma, contando
eventos por município, por mês ou por hora) e realizar a comparação de
modelos por validação cruzada.
