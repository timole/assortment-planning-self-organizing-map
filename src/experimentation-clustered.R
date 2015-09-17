# TODO: Add comment
# 
# Author: timole
###############################################################################

library("data.table")

#windows(width = 16, height = 9)
#par(mfrow = c(1, 1))

# nrow(ap[ap$inTest == T & ap$isInAssortmentWholePeriod3m == T,])
# [1] 270



set.seed(1) #1, 7

doNorm <- function(x) {
	(x - min(x, na.rm=TRUE))/(max(x,na.rm=TRUE) - min(x, na.rm=TRUE))
}

clustered <- function(ap, nClusters) {
	m <- ap[,c("assortmentSizeDuringPeriod", "totalSalesDuringPeriod", "salesPerAssortmentPlace")] # ,,,     
	
	normedM <- as.data.frame(lapply(m, doNorm))

	cl <- kmeans(normedM, nClusters, nstart = 25, iter.max = 30)
	plot(m, col = cl$cluster)
	points(cl$centers, col = 1:nClusters, pch = 8)
	
	ap$cl <- cl$cluster
	
	ap
}

# Note: only assortment products that were present for three months are taken into account
clusteredAp <- clustered(ap[ap$isInAssortmentWholePeriod3m == T,], 9) 

#head(clusteredAp)

clusters <- sort(unique(clusteredAp$cl))

#table(clusteredAp$cl)

productSomeLimits <- lapply(productNames, function(productName) {
	productName <- as.character(productName)
	
	clProductSomeLimit <- data.frame(clusters, productName, sapply(clusters, function(cl) {
		clAp <- clusteredAp[clusteredAp$cl == cl & clusteredAp$productName == productName,]
		median(clAp$SOME)
	}))
	colnames(clProductSomeLimit) <- c("cl", "productName", "clProductSomeLimit")
	clProductSomeLimit
})
#productSomeLimits 
getProductSomeLimits <- function(productName, productNames, productSomeLimits, cl) {
	pslByCl <- productSomeLimits[match(productName, productNames)][[1]]
	pslByCl[as.numeric(pslByCl$cl) == as.numeric(cl),]$clProductSomeLimit
}

#pslByCl
clusteredAp$apSomeExceedsPslByCl <- apply(clusteredAp, 1, function(row) {
	apSome <- as.numeric(row["SOME"])
	pslByCl <- as.numeric(getProductSomeLimits(row["productName"], productNames, productSomeLimits, row["cl"]))
	
	exceeds <- F
	if(apSome > pslByCl) {
		exceeds <- T
	} else {
		exceed <- F
	}
	return(exceeds)
})



productSomcLimits <- lapply(productNames, function(productName) {
	productName <- as.character(productName)
	clProductSomcLimit <- data.frame(clusters, productName, sapply(clusters, function(cl) {
						clAp <- clusteredAp[clusteredAp$cl == cl & clusteredAp$productName == productName,]
						median(clAp$SOMC)
					}))
	colnames(clProductSomcLimit) <- c("cl", "productName", "clProductSomcLimit")
	clProductSomcLimit
})
getProductSomcLimits <- function(productName, productNames, productSomcLimits, cl) {
	pslByCl <- productSomcLimits[match(productName, productNames)][[1]]
	pslByCl[as.numeric(pslByCl$cl) == as.numeric(cl),]$clProductSomcLimit
}
clusteredAp$apSomcExceedsPslByCl <- apply(clusteredAp, 1, function(row) {
	apSomc <- as.numeric(row["SOMC"])
	pslByCl <- as.numeric(getProductSomcLimits(row["productName"], productNames, productSomcLimits, row["cl"]))
	
	exceeds <- F
	if(apSomc > pslByCl) {
		exceeds <- T
	} else {
		exceed <- F
	}
	return(exceeds)
})


productTcovLimits <- lapply(productNames, function(productName) {
	productName <- as.character(productName)
	clProductTcovLimit <- data.frame(clusters, productName, sapply(clusters, function(cl) {
		clAp <- clusteredAp[clusteredAp$cl == cl & clusteredAp$productName == productName,]
		median(clAp$SOMC)
	}))
	colnames(clProductTcovLimit) <- c("cl", "productName", "clProductTcovLimit")
	clProductTcovLimit
})
getProductTcovLimits <- function(productName, productNames, productTcovLimits, cl) {
	pslByCl <- productTcovLimits[match(productName, productNames)][[1]]
	pslByCl[as.numeric(pslByCl$cl) == as.numeric(cl),]$clProductTcovLimit
}
clusteredAp$apTcovExceedsPslByCl <- apply(clusteredAp, 1, function(row) {
	apTcov <- as.numeric(row["TCOV"])
	pslByCl <- as.numeric(getProductTcovLimits(row["productName"], productNames, productTcovLimits, row["cl"]))
	
	exceeds <- F
	if(apTcov > pslByCl) {
		exceeds <- T
	} else {
		exceed <- F
	}
	return(exceeds)
})

#head(clusteredAp)


results <- data.frame()
for(productName in productNames) {
	productName <- as.character(productName)
	for(cl in clusters) {
		print(sprintf("############# %s / cluster %d ", productName, cl))

		clap <- clusteredAp[clusteredAp$cl == cl & clusteredAp$productName == productName,]
		clapLte <- clap[clap$apSomeExceedsPslByCl == F,]
		clapLteZsp <- round(nrow(clapLte[clapLte$soldEur == 0,]) / nrow(clapLte) * 100, 0)
		
		clapZsp <- round(nrow(clap[clap$soldEur == 0,]) / nrow(clap) * 100, 0)
		
		clapGt <- clap[clap$apSomeExceedsPslByCl == T,]
		clapGtZsp <- round(nrow(clapGt[clapGt$soldEur == 0,]) / nrow(clapGt) * 100, 0)
	
		if(nrow(clap) < 30 | nrow(clapLte) < 30 | nrow(clapGt) < 30) {
			print(sprintf("Skipping %d observations (lte %d, gt %d), because N<30", nrow(clap), nrow(clapLte), nrow(clapGt)))
		} else {
			
	
			df <- data.frame(
				productName = productName,
				cl = cl,
				nInTest = nrow(clap[clap$inTest == T,]),
				nInTestAndGt = nrow(clap[clap$inTest == T & clap$apSomeExceedsPslByCl == T,]),
				nInTestAndGtTcov = nrow(clap[clap$inTest == T & clap$apSomeExceedsPslByCl == T & clap$apTcovExceedsPslByCl == T,]),
				nOk = nrow(clap[clap$inTest == T & !is.na(clap$wasPredictingGood) & clap$wasPredictingGood == T & !is.na(clap$wasPredictingFutureTcovGtMedian) & clap$wasPredictingFutureTcovGtMedian == T,]), # & clap$SOMC >= 0.5 & clap$NTCOV >= 2  & clap$SOME >= 1/4
				nR = nrow(clap[clap$cl == selectedCl & clap$inTest == T & (is.na(clap$wasPredictingGood) | clap$wasPredictingGood == F | is.na(clap$wasPredictingFutureTcovGtMedian) | clap$wasPredictingFutureTcovGtMedian == F),]),
				nClapLte = nrow(clapLte), clapLteZsp = clapLteZsp, #clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == T & !is.na(clusteredAp$wasPredictingGood) & clusteredAp$wasPredictingGood == T & !is.na(clusteredAp$wasPredictingFutureTcovGtMedian) & clusteredAp$wasPredictingFutureTcovGtMedian == T ,] #
				nClap = nrow(clap), clapZsp = clapZsp, 
				nClapGt = nrow(clapGt), clapGtZsp = clapGtZsp, zspDiff = clapGtZsp - clapLteZsp, 
				clapMeanAssortmentSize = round(mean(clap$assortmentSizeDuringPeriod), 0), 
				clapLteMeanAssortmentSize = round(mean(clapLte$assortmentSizeDuringPeriod), 0), 
				clapGtMeanAssortmentSize = round(mean(clapGt$assortmentSizeDuringPeriod), 0),
				clapMeanTotalSales = round(mean(clap$totalSalesDuringPeriod), 0), 
				clapLteMeanTotalSales = round(mean(clapLte$totalSalesDuringPeriod), 0), 
				clapGtMeanTotalSales = round(mean(clapGt$totalSalesDuringPeriod), 0),
				clapMedianAssortmentSize = round(median(clap$assortmentSizeDuringPeriod), 0), 
				clapLteMedianAssortmentSize = round(median(clapLte$assortmentSizeDuringPeriod), 0), 
				clapGtMedianAssortmentSize = round(median(clapGt$assortmentSizeDuringPeriod), 0),
				clapMedianTotalSales = round(median(clap$totalSalesDuringPeriod), 0), 
				clapLteMedianTotalSales = round(median(clapLte$totalSalesDuringPeriod), 0), 
				clapGtMedianTotalSales = round(median(clapGt$totalSalesDuringPeriod), 0),
				clapHeatMean = round(mean(clap$totalSalesDuringPeriod) / (mean(clap$assortmentSizeDuringPeriod)), 0),
				clapLteHeatMean = round(mean(clapLte$totalSalesDuringPeriod) / (mean(clapLte$assortmentSizeDuringPeriod)), 0),
				clapGtHeatMean = round(mean(clapGt$totalSalesDuringPeriod) / (mean(clapGt$assortmentSizeDuringPeriod)), 0),
				clapGtPerLteHeatMean = round( mean(clapGt$totalSalesDuringPeriod) / (mean(clapGt$assortmentSizeDuringPeriod) ) / (mean(clapLte$totalSalesDuringPeriod) / (mean(clapLte$assortmentSizeDuringPeriod))), 2)
				)
			results <- rbind(results, df)
		}
	}
}

results <- results[with(results, order(nOk, decreasing = T)),] # nInTestAndGt
head(results)

aggregated <- aggregate(results$nOk, by = list(cl = results$cl), FUN=sum) # nInTestAndGt
colnames(aggregated) <- c("cl", "nOk") #nInTestAndGt 
aggregated

selectedCl <- 1

clap <- clusteredAp[clusteredAp$cl == selectedCl,]
nrow(clap)
#groupA <- clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == T & clusteredAp$SOME >= 1/4 & clusteredAp$NTCOV >= 2,] # 
#groupA <- clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == T & clusteredAp$SOMC >= 0.2,] # wasPredictingFutureTcovGtMedian
groupA <- clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == T & !is.na(clusteredAp$wasPredictingGood) & clusteredAp$wasPredictingGood == T & !is.na(clusteredAp$wasPredictingPotential) & clusteredAp$wasPredictingPotential == T,] # 

#groupB <- clusteredAp[clusteredAp$cl == selectedCl & (clusteredAp$inTest == F | clusteredAp$SOME < 1/4 | clusteredAp$NTCOV < 2),]
#groupF <- clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == T & (clusteredAp$SOME < 1/4 | clusteredAp$NTCOV < 2),]
groupB <- clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == F,]
#groupB <- clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == F,]
groupR <- clusteredAp[clusteredAp$cl == selectedCl & clusteredAp$inTest == T & (is.na(clusteredAp$wasPredictingGood) | clusteredAp$wasPredictingGood == F | is.na(clusteredAp$wasPredictingFutureTcovGtMedian) | clusteredAp$wasPredictingFutureTcovGtMedian == F),]

table(groupA$productName)

clapAnalysis <- analyzeIt(clap, "clap (all in cluster)")
groupAAnalysis <- analyzeIt(groupA, "group A")
groupBAnalysis <- analyzeIt(groupB, "group B")
groupRAnalysis <- analyzeIt(groupR, "group R")

clapAnalysis
groupAAnalysis
groupBAnalysis
groupRAnalysis

table(groupAInTest$productName)

wilcox.test(groupA$assortmentSizeDuringPeriod, groupB$assortmentSizeDuringPeriod)$p.value
wilcox.test(groupA$totalSalesDuringPeriod, groupB$totalSalesDuringPeriod)$p.value
wilcox.test(groupA$salesPerAssortmentPlace, groupB$salesPerAssortmentPlace)$p.value

m <- matrix( nrow = 2, ncol = 2, 
		c(nrow(groupA[groupA$soldEur == 0,]), nrow(groupB[groupB$soldEur == 0,]),
				nrow(groupA), nrow(groupB)))
chisq.test(m)

lowSalesGroupA <- groupA[groupA$soldEur < median(groupA$soldEur),]$soldEur
lowSalesGroupB <- groupB[groupB$soldEur < median(groupB$soldEur),]$soldEur

wilcox.test(groupA$soldEur, groupB$soldEur)$p.value
