# Análise de Regularização (Ridge & Lasso) - 1º Trimestre ($2017\text{--}2026$)

Na análise de regularização para a movimentação de cargas no 1º Trimestre ($2017\text{--}2026$), a matriz expandida de $248$ preditores apresentava elevada colinearidade devido à especificação de berços e terminais. 

O ajuste via Lasso ($L_1$) com a regra de $1$ erro padrão ($\lambda_{1\text{se}} = 46,6639$) reduziu o modelo para $93$ preditores ativos, eliminando $155$ coeficientes redundantes. 

O modelo parcimonioso manteve um RMSE de Validação Cruzada de $3.803,90$ toneladas, praticamente equivalente ao ponto mínimo ($3.766,17$ toneladas), provando que o volume exportado é fortemente concentrado nos granéis sólidos (soja e milho), derivados de petróleo (bunker e óleo combustível) e infraestruturas específicas de grande porte (T-Grão, Bracell, TEG e TGG).