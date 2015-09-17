# initialize data

# 1. run SOM_PAK
# 2. run count-SOM-salesIndex.R
# 3. add the products to assortment

library(jsonlite)

outletIds <- fromJSON(txt = "outletIds.json")
productIds <- fromJSON(txt = "productIds.json")

salesHistory <- as.data.frame(fromJSON(txt = "salesHistory.json"))
rownames(salesHistory) <- outletIds
colnames(salesHistory) <- productIds

totalSales <- as.data.frame(apply(salesHistory, 1, sum))
rownames(totalSales) <- rownames(salesHistory)

parseSomJson <- function(fileName) {
  somTable <- as.data.frame(fromJSON(txt = fileName))

  similarItems <- list()
  for(ids in somTable[[3]]) {
    for(id in ids) {
      similarItems[[as.character(id)]] <- ids
    }
  }
  return(similarItems)
}

somOutlets <- parseSomJson("outletSomTable.json")
somProducts <- parseSomJson("productSomTable.json")

cppFunction('double cppCountLessThan() {
  return 999;
}')


# NumericMatrix salesHistory, NumericMatrix totalSales, NumericMatrix somProducts, NumericMatrix somOutlets, int productId, int outletId

salesHistoryM <- as.matrix(salesHistory)
totalSalesM <- as.matrix(totalSales)

str(somProducts)

cppFunction('double cppCountSOME(NumericMatrix salesHistory, NumericMatrix totalSales, List somProducts, List somOutlets, std::string productId, std::string outletId) {
  NumericVector productsOnSom = somProducts[productId];
  NumericVector outletsOnSom = somOutlets[outletId];

  int someN = 0;
  double someSum = 0;

//  for(int i = 0; i < outletsOnSom.size(); i++) {
//    for(int j = 0; j < productsOnSom.size(); j++) {
//    }
//  }

      someSum += 0.123;
      someN++;

  return (double) someSum / someN;
}')

cppCountSOME(salesHistoryM, totalSalesM, somProducts, somOutlets, as.character(998888), as.character(123456))



countSOME <- function(salesHistory, totalSales, productsOnSom , outletsOnSom , productId, outletId) {
  someN <- 0
  someSum <- 0

  for(somOutletId in outletsOnSom) {
    outletSales <- salesHistory[as.character(somOutletId),]
    outletTotalSales <- totalSales[as.character(somOutletId),]
    for(somProductId in productsOnSom) {

      outletProductSales <- salesHistory[as.character(somOutletId), as.character(somProductId)]
      if(outletProductSales > 0 & (somOutletId != outletId | somProductId != productId)) {
        lessThanProductSales <- sum(outletSales[outletSales < outletProductSales])
        some <- lessThanProductSales / outletTotalSales
        someN <- someN + 1
        someSum <- someSum + some
      }
    }
  }
  return(someSum / someN)
}

countSOME(salesHistory, totalSales, somProducts, somOutlets, 888777, 111222)


outletProductSales <- read.csv("../output.csv", sep=";", row.names = 1, header = TRUE)
colnames(outletProductSales) <- gsub("X", "", colnames(outletProductSales))

productIds <- colnames(outletProductSales)
outletIds <- rownames(outletProductSales)

numberOfPoints <- sum(!is.na(outletProductSales))

somes <- matrix(ncol = length(productIds), nrow = length(outletIds))

colnames(somes) <- productIds
rownames(somes) <- outletIds
maxN <- length(productIds) * length(outletIds)
n <- 0
row <- 1
col <- 1
for(productId in productIds) {
  row <- 1
  for(outletId in outletIds) {
    if(!is.na(outletProductSales[outletId, productId])) {
      productsOnSom <- somProducts[[as.character(productId)]]
      outletsOnSom <- somOutlets[[as.character(outletId)]]

      print(sprintf("%.2f%%: %d,%d: productId: %s outletId: %s  nProducts: %d  nOutlets: %d", n / numberOfPoints * 100, row, col, productId, outletId, length(productsOnSom), length(outletsOnSom)))
      flush.console()
      some <- countSOME(salesHistoryM, totalSalesM, productsOnSom, outletsOnSom , as.character(productId), as.character(outletId))
      
      somes[row, col] <- some
      n <- n + 1
    }
    row <- row + 1
  }
  col <- col + 1
}
date()


somes["111222", "222333"]

# a simple test
print(sprintf("%.3f is equal to %.3f", somes["111222", "333444"], 0.159))


