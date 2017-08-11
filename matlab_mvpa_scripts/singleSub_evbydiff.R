rm(list=ls())

library(doBy)
library(car)
library(ggplot2)

se=function(x)(sd(x)/sqrt(length(x)))

data=read.csv('~/Documents/forcemem_mriDat/forcemem_2017080901/mvpa_results/allProbesTraining.csv')
data$block=as.factor(data$block)
data$diffRev=16-data$probeDiff
str(data)

data_allPM=data[data$pmType<3,]
str(data_allPM)

evSum=summaryBy(diffEV~diffRev, data=data_allPM,FUN=c(mean,se,length))
evSum

lm1=lm(diffEV.mean~diffRev,data=evSum)
summary(lm1)

ggplot(data=evSum,aes(x=diffRev,y=diffEV.mean)) +
	#stat_smooth(method="glm", se=T, colour="black") +
	geom_line() +
	geom_errorbar(aes(ymin=diffEV.mean-diffEV.se,ymax=diffEV.mean+diffEV.se)) +
	ggtitle('') +
  	labs(x='Difficulty (Hard to Easy)') +
  	labs(y='Classifier Evidence Difference (Target-nonTarget)')