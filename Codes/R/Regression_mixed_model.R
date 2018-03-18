

##################################
#                                #
#   EXAMPLE : LASSO REGRESSION   #
#                                #
##################################

# Cf. : https://www.r-bloggers.com/linear-mixed-models-in-r/

library(MASS)
library(nlme)

data(oats)
colnames(oats) = c('block', 'variety', 'nitrogen', 'yield')
# oats$mainplot = oats$variety
# oats$subplot = oats$nitrogen

summary(oats)



m1.nlme = lme(yield ~ variety*nitrogen, random = ~ 1|block/variety, data = oats)

summary(m1.nlme)







