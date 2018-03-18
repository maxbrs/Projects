

##################################
#                                #
#   EXAMPLE : LASSO REGRESSION   #
#                                #
##################################

# Cf. : https://www.r-bloggers.com/ridge-regression-and-the-lasso/

library(glmnet)

swiss <- datasets::swiss

x <- model.matrix(Fertility~., swiss)[,-1]
y <- swiss$Fertility
lambda <- 10^seq(10, -2, length = 100)
# First, let's prove the fact that when λ = 0 we get the same coefficients as the OLS model.


#create test and training sets
set.seed(489)
train = sample(seq(1,nrow(x)), nrow(x)/2)
test = (-train)
ytest = y[test]

#OLS
swisslm <- lm(Fertility~., data = swiss)
coef(swisslm)

#ridge
ridge.mod <- glmnet(x, y, alpha = 0, lambda = lambda)
predict(ridge.mod, s = 0, type = 'coefficients')[1:6,]



# The differences here are nominal. Let's see if we can use ridge to improve on the OLS estimate.
swisslm <- lm(Fertility~., data = swiss, subset = train)
ridge.mod <- glmnet(x[train,], y[train], alpha = 0, lambda = lambda)
#find the best lambda from our list via cross-validation
cv.out <- cv.glmnet(x[train,], y[train], alpha = 0)

bestlam <- cv.out$lambda.min

#make predictions
ridge.pred <- predict(ridge.mod, s = bestlam, newx = x[test,])
s.pred <- predict(swisslm, newdata = swiss[test,])

#check MSE
mean((s.pred-ytest)^2)
mean((ridge.pred-ytest)^2)


#a look at the coefficients
out = glmnet(x[train,],y[train],alpha = 0)
predict(ridge.mod, type = "coefficients", s = bestlam)[1:6,]

# As expected, most of the coefficient estimates are more conservative.

# Let's have a look at the lasso. The big difference here is in the shrinkage term
#the lasso takes the absolute value of the coefficient estimates.

lasso.mod <- glmnet(x[train,], y[train], alpha = 1, lambda = lambda)
lasso.pred <- predict(lasso.mod, s = bestlam, newx = x[test,])
mean((lasso.pred-ytest)^2)

lasso.coef  <- predict(lasso.mod, type = 'coefficients', s = bestlam)





