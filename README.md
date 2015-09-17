# Assortment Planning with the Self-Organizing Map

We applied the self-organizing map (SOM) to solve an assortment planning problem for our customer (Lehtipiste). We introduce a case study in a still unpublished paper  where data science approach is used to optimize a supply chain of single-copy magazines in Finland. The initial results of a yet show, that the sales is improved by 29% (http://www.solita.fi/ajankohtaista/solita-science-edellakavijyytta-tutkimuksen-kautta/). 

The work on this method has been currently stopped because there are no currently resources to advance in the research. Need 4 Speed program (http://n4s.fi) has helped a lot in the experimentation and academic work so far.

Empirical real world experimentation with 8 products and some hundred sales outlets together with a simulation showed resulted to an improvement of 45%. It is still unkown how the solution applies to the total yearly sales of single copy magazines in Finland.

The method is simple and straight-forward:

!(img/neural-networks.png)

1. Export sales data of previous period
2. Organize the sales data with the SOM
3. Count SSI and SCO in the SOM neighborhood and median in the real-world neighborhood.
4. An SSI value > median and SCO > median predicts good sales

The same expressed as an experiment with K-means clustering of three control variables and Whitney-Mann U test:

Hypothesis:

Higher SOM-sales index (SSI) and SOM-coverage (SCO) values together with target outlet SOM-coverage (TOC) help to prevent zero sales in a highly optimized environment. Helper variables: number of products with similar sales profile Nspp  and sales outlets Nsop

Independent variable: a value of 0 or 1 indicating SSI > median of real-world neighborhood (assortment size and total sales), SCO  > median of real-world neighborhood and TOC > 2/Nsp , where Nsp = number of outlets with similar sales profile on

Control variables:
Assortment size (as)
Total sales (ts)
Sales per place (spp = ts/as)

Experiment:

We applied K-means clustering for the control variables (as, ts & spp) with N of 9 clusters in order to acquire comparable product-outlet-pairs
Clusters with at least 30 additions were investigated in detail.

Whitney Mann U-test for Control variables were: P-values 0.8, 0.4 and 0.3

Result for Whitney Mann U-test for sales in currency for groups A and B was P-value of 0.06

Simulation:

In addition to this we created a simulation
In April 2014 products A, B, C, D, E, F, G and H were added to several outlets.
An algorithm removed the same products from different outlets with the following logic:
1. Select outlets with same size (assortment size and sales +-30%)
2. Filter product-outlets to outletSales < q1 and productSales < median
3. Filter product-outlets with smaller SSI and SCO values
4. Remove the product-outlet with lowest SSI

The simulation resulted to 45% increase in sales. 

Limitations:
The experiment was done in a small scale. It is unknown how e.g. product cannibalism affects the total change or how the other 1500 products and 4000 sales outlets behave in a similar setting.


In the best case, this approach could work in any domain with thousands of products and sales outlets:

!(img/som-where.png)

In practice, the method works as follows:

!(img/som-anim.gif)

