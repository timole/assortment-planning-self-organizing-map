#!/usr/bin/python

import re, sys, json
import xml.etree.ElementTree as et
import numpy

def parseColumnNames(csv):
    columnNames = re.split(',', csv)
    result = []
    for columnName in columnNames:
        result.append(columnName.replace(' ', '').replace('"', '').strip())
    return result

def parseRowData(csv):
    values = re.split(',', csv)
    result = []
    for value in values:
        if(value.strip()[0] == '"' and value.strip()[-1] == '"'):
            value = value.strip()[1:-1]
        result.append(value.strip())
    return result

# "SALES_PERIOD_TILL_DAY","SALES_YEAR_WEEK","OUTLET_ID","PERIODICAL_PRODUCT_ID","PRODUCT_ID","DELIVERED","RETURNED","SOLD"

periodId = sys.argv[1]
filename = sys.argv[2]
outputFilename = sys.argv[3]
outputFilename2 = sys.argv[4]
outputFilenameOutletJs = sys.argv[5]
outputFilename3 = sys.argv[6]

f = open(filename, "r")
out = open(outputFilename, "w")
out2 = open(outputFilename2, "w")
outOutletJs = open(outputFilenameOutletJs, "w")
out3 = open(outputFilename3, "w")

print "Period id: " + periodId
print "Input file: " + filename
print "Output file: " + outputFilename
print "JS output file: " + outputFilenameOutletJs

first = True
dataparsed = False


j = {}
data = []
root = {}
data.append(root)
fields = []
rows = []
parsed = 0

outletIdSet = set()
productIdSet = set()
i = 0
maxLines = -1 #100

#DATE_INDEX=0
#YEAR_WEEK_INDEX=1
OUTLET_ID_INDEX=0
#PERIODICAL_PRODUCT_ID_INDEX = 1
#PRODUCT_ID_INDEX = 1
PERIODICAL_PRODUCT_ID_INDEX = 1
#DELIVERED_INDEX = 5
#RETURNED_INDEX = 6
SOLD_INDEX = 2

for line in f:
    if first:
        columnNames = parseColumnNames(line)
        for columnName in columnNames:
            print "col: " + columnName
        first = False
    else:
        if i == maxLines:
            break
        i = i + 1
        rowData = parseRowData(line)
        outletId = rowData[OUTLET_ID_INDEX]
        productId = rowData[PERIODICAL_PRODUCT_ID_INDEX]
        sold = float(rowData[SOLD_INDEX])

        if outletId not in outletIdSet:
            outletIdSet.add(outletId)

        if productId not in productIdSet:
            productIdSet.add(productId)

        if i % 1000 == 0:
            sys.stdout.write(".")
            sys.stdout.flush()

numOutlets = len(outletIdSet)
numProducts = len(productIdSet)

print
print "outlets: " + str(numOutlets)
print "products: " + str(numProducts)

outletIds = list(outletIdSet)
productIds = list(productIdSet)

m = numpy.zeros( (numProducts, numOutlets), dtype=numpy.float)
for i in range(0, numProducts):
    for j in range(0, numOutlets):
        m[i, j] = -1

f = open(filename, "r")
first = True
i = 0
for line in f:
    if first:
        first = False
    else:
        if i == maxLines:
            break
        i = i + 1
        rowData = parseRowData(line)
        outletId = rowData[OUTLET_ID_INDEX]
        productId = rowData[PERIODICAL_PRODUCT_ID_INDEX]
        sold = float(rowData[SOLD_INDEX])

        row = productIds.index(productId)
        col = outletIds.index(outletId)

        prev = float(m[row, col])
        if prev == -1:
            prev = 0

        m[row, col] = prev + float(sold)
        m[row, col] = float(sold)

        if i % 1000 == 0:
            sys.stdout.write(".")
            sys.stdout.flush()

print
print numOutlets
out.write(str(numOutlets) + '\n')
out.write("# ")
for outletId in outletIds:
    out.write(str(outletId) + " ")
out.write('\n')

for i in range(0, numProducts):
    for j in range(0, numOutlets):
        val = m[i,j]
        if val == -1:
            val = ""
        else:
            val = str(val)
        out.write(val + " ")

    out.write(productIds[i])
    out.write('\n')
    sys.stdout.write(".")
    sys.stdout.flush()


print
print numProducts
out2.write(str(numProducts) + '\n')
out2.write("# ")
isFirstProductId = True
out3.write(";")
for productId in productIds:
    if(not isFirstProductId):
        out3.write(";")
    isFirstProductId = False
    out2.write(str(productId) + " ")
    out3.write(str(productId))
out2.write('\n')
out3.write('\n')

for i in range(0, numOutlets):
    out3.write(outletIds[i])
    out3.write(";")
    isFirstProductId = True
    for j in range(0, numProducts):
        val = m[j,i]
        if val == -1:
            val = ""
        else:
            val = str(val)
        out2.write(val + " ")
        if(not isFirstProductId):
            out3.write(";")
        isFirstProductId = False
        out3.write(val)

    out2.write(outletIds[i])
    out2.write('\n')
    out3.write('\n')
    sys.stdout.write(".")
    sys.stdout.flush()

print
print "Outlet JS"
varName = "outletSalesByPeriod";
outOutletJs.write("var "+varName+" = "+varName+" || {};\n\n");
outOutletJs.write(varName+"[\"" + periodId + "\"] = {};\n");
outOutletJs.write(varName+"[\"" + periodId + "\"].outletIds = ");
json.dump(outletIds, outOutletJs)
outOutletJs.write(";\n");
outOutletJs.write(varName+"[\"" + periodId + "\"].productIds = ");
json.dump(productIds, outOutletJs)
outOutletJs.write(";\n");
outletSales = []
for i in range(0, numOutlets):
    outletId = outletIds[i]
    productSales = []
    outletSales.append(productSales)
    for j in range(0, numProducts):
        val = m[j,i]
        if val == -1:
            val = 0
        productId = productIds[j]
        productSales.append(val)
outOutletJs.write(varName+"[\"" + periodId + "\"].sold = ");
json.dump(outletSales, outOutletJs)
outOutletJs.write(";\n");


out.close()
out2.close()
outOutletJs.close()
out3.close()

print
print "Finished."
