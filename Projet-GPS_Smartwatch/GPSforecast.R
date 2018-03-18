
library(ggplot2)


####################################################
#                                                  #
# USING GPS DATA TO FORECAST A RUNNER'S TRAJECTORY #
#                                                  #
####################################################

df <- read.csv("~/Kaggle/OnboardGPS.csv")
head(df)

df$Timpstemp <- as.numeric(df$Timpstemp)/1000000
df$Timpstemp <- round(df$Timpstemp - min(df$Timpstemp), 2)
df <- cbind(df$Timpstemp, df$lat, df$lon, df$alt)
df <- as.data.frame(df)
colnames(df) <- c("time", "lat", "lon", "alt")

# plot(x = df$lat, y = df$lon, type = "l")

time <- seq(from = 0, to = 45*60, by = 1)
f <- approxfun(df$time, df$lat, method = "linear")
lat <- f(time)
f <- approxfun(df$time, df$lon, method = "linear")
lon <- f(time)
f <- approxfun(df$time, df$alt, method = "linear")
alt <- f(time)

df <- cbind(time, lat, lon, alt)
df <- as.data.frame(df)



# par(mfrow = c(1,2))
# plot(x = df$time, y = df$lat)

# PLOT
#------

plot(x = df$lat, y = df$lon, type = "l", main = "Here we are plotting one point over 20 seconds", cex.main = 0.9)

sequential = 25
for(i in seq(1, round(nrow(df)/sequential))){
  if(i%%10 == 0) {print(paste("Progress = ", round((i/(nrow(df)/sequential))*100,2), "%"))}
  
  points(x = df$lat[i*sequential], y = df$lon[i*sequential], col = "red")
  # points(x = esti_lat[i*sequential], y = esti_lon[i*sequential], col = "blue")
  
  Sys.sleep(0.25)
}





plot(df$time, df$lat, type = "l")



data <- df$lat
esti <- NULL
d = 1000
f = 1150
plot(df$time[seq(d,f)], df$lat[seq(d,f)], type = "o")


time <- seq(d,f)

alpha = 0.763

best_ssfe = 1000
best_alpha = 0

for(alpha in seq(0.001, 0.999, by = 0.001)) {
  ssfe = 0
  for(i in time) {
    gap1 <- data[i-1] - data[i-2]
    gap2 <- data[i-2] - data[i-3]
    # gap3 <- data[i-3] - data[i-4]
    # gap4 <- data[i-4] - data[i-5]
    # gap5 <- data[i-5] - data[i-6]
    esti[i] <- data[i-1] + gap1*alpha + gap2*(1-alpha)
    ssfe = ssfe + (esti[i] - data[i])^2
  }

  if (ssfe < best_ssfe) {
    best_ssfe = ssfe
    best_alpha = beta
  }
}

print(best_ssfe)
print(best_alpha) # 0.763
  

# ssfe gap1*1 = 2.1184e-10

plot(df$time[seq(d,f)], df$lat[seq(d,f)], type = "o")

for(i in seq(d, f)){
  if(i%%5 == 0) {print(paste("Progress =", round(((i-d)/(f-d))*100,2), "%"))}
  
  points(x = df$time[i], y = df$lat[i], col = "blue") # Real data
  points(x = df$time[i], y = esti[i], col = "red") # Estimated data
  
  Sys.sleep(1)
}



#--------------------------------



df <- read.csv("~/PROJETS/ProjetQlikDrone/data/data.csv")


df$dates <- as.integer(df$dates)
df$remaining <- as.numeric(df$remaining)

plot(x=df$dates, y=df$remaining, type = "l", ylim=c(0,1), xlim=c(0,2000))

reg <- lm(remaining~dates, data = df)
# reg2 <- lm(remaining ~ dates + I(dates^2), data = df)
abline(reg, col = "red")
# lines(x=x, y=reg$coefficients[1]+x*reg$coefficients[2], col = "blue")


rem_time = (solve(reg$coefficients[2],-reg$coefficients[1]) - max(df$dates)) / 60
print(paste("Time remaining before out of service (in min) =",round(rem_time,2)))





