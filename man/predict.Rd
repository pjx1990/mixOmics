\name{predict}
\encoding{UTF-8}
\alias{predict}
\alias{predict.pls}
\alias{predict.spls}
\alias{predict.plsda}
\alias{predict.splsda}

\alias{predict.mint.pls}
\alias{predict.mint.spls}
\alias{predict.mint.plsda}
\alias{predict.mint.splsda}

\alias{predict.mint.block.pls}
\alias{predict.mint.block.spls}
\alias{predict.mint.block.plsda}
\alias{predict.mint.block.splsda}


\title{Predict Method for (mint).(block).(s)pls(da) methods}

\description{
Predicted values based on PLS models. New responses and
variates are predicted using a fitted model and a new matrix of observations.
}

\usage{
\method{predict}{mint.splsda}(object, newdata, study.test,
dist = c("all", "max.dist", "centroids.dist", "mahalanobis.dist"),
multilevel, \ldots)
}

\arguments{
\item{object}{object of class inheriting from \code{"(mint).(block).(s)pls(da)"}.}
\item{newdata}{data matrix in which to look for for explanatory variables to be used for prediction. Please note that this method does not perform multilevel decomposition or log ratio transformations, which need to be processed beforehand.}
\item{study.test}{For MINT objects, grouping factor indicating which samples of \code{newdata} are from the same study. Overlap with \code{object$study} are allowed.}
\item{dist}{distance to be applied for discriminant methods to predict the class of new data,
should be a subset of \code{"centroids.dist"}, \code{"mahalanobis.dist"} or \code{"max.dist"} (see Details).
Defaults to \code{"all"}.}
\item{multilevel}{Design matrix for multilevel analysis (for repeated measurements). A numeric matrix or data frame. For a one level factor decomposition, the input is a vector indicating the repeated measures on each individual, i.e. the individuals ID. For a two level decomposition with splsda models, the two factors are included in Y. Finally for a two level decomposition with spls models, 2nd AND 3rd columns in design indicate those factors (see example in \code{?splsda} and \code{?spls}).}
\item{...}{not used currently.}
}

\details{
\code{predict} produces predicted values, obtained by evaluating the PLS-derived methods, returned by \code{(mint).(block).(s)pls(da)} in the frame \code{newdata}.
Variates for \code{newdata} are also returned. Please note that this method performs multilevel decomposition and/or log ratio transformations if needed (\code{multilevel} is an input parameter while \code{logratio} is extracted from \code{object}).

Different prediction distances are proposed for discriminant analysis. The reason is that our supervised models work with a dummy indicator matrix of \code{Y} to indicate the class membership of each sample. The prediction of a new observation results in either a predicted dummy variable (output \code{object$predict}), or a predicted variate (output \code{object$variates}). Therefore, an appropriate distance needs to be applied to those predicted values to assign the predicted class. We propose distances such as `maximum distance' for the predicted dummy variables, `Mahalanobis distance' and `Centroids distance' for the predicted variates.


\code{"max.dist"} is the simplest method to predict the class of a test sample. For each new individual, the class with the largest predicted dummy variable is the predicted class. This distance performs well in single data set analysis with multiclass problems (PLS-DA).

\code{"centroids.dist"}  allocates to the new observation the class that mimimises the distance between the predicted score and the centroids of the classes calculated on the latent components or variates of the trained model.

\code{"mahalanobis.dist"}  allocates the new sample the class defined as the centroid distance, but using the Mahalanobis metric in the calculation of the distance.

In practice we found that the centroid-based distances (\code{"centroids.dist"} and \code{"mahalanobis.dist"}), and specifically the Mahalanobis distance led to more accurate predictions than the maximum distance for complex classification problems and N-integration problems (block.splsda). The centroid distances consider the prediction in dimensional space spanned by the predicted variates, while the maximum distance considers a single point estimate using the predicted scores on the last dimension of the model. The user can assess the different distances, and choose the prediction distance that leads to the best performance of the model, as highlighted from the tune and perf outputs

More (mathematical) details about the prediction distances are available in the supplemental of the mixOmics article (Rohart et al 2017).


For a visualisation of those prediction distances, see \code{background.predict} that overlays the prediction area in \code{plotIndiv} for a sPLS-DA object.


%allocates the individual \eqn{x} to the class of \eqn{Y} minimizing \eqn{dist(\code{x-variate}, G_l)}, where \eqn{G_l}, \eqn{l = 1,...,L} are the centroids of the classes calculated on the \eqn{X}-variates of the model. \code{"mahalanobis.dist"} allocates the individual \eqn{x} to the class of \eqn{Y} as in \code{"centroids.dist"} but by using the Mahalanobis metric in the calculation of the distance.

For MINT objects, the \code{study.test} argument is required and provides the grouping factor of \code{newdata}.

For multi block analysis (thus block objects), \code{newdata} is a list of matrices whose names are a subset of \code{names(object$X)} and missing blocks are allowed. Several predictions are returned, either for each block or for all blocks.
For non discriminant analysis, the predicted values (\code{predict}) are returned for each block and these values are combined by average (\code{AveragedPredict}) or weighted average (\code{WeightedPredict}), using the weights of the blocks that are calculated as the correlation between a block's components and the outcome's components.

For discriminant analysis, the predicted class is returned for each block (\code{class}) and each distance (\code{dist}) and these predictions are combined by majority vote (\code{MajorityVote}) or weighted majority vote (\code{WeightedVote}), using the weights of the blocks that are calculated as the correlation between a block's components and the outcome's components. NA means that there is no consensus among the block. For PLS-DA and sPLS-DA objects, the prediction area can be visualised in plotIndiv via the \code{background.predict} function.

}

\value{
\code{predict} produces a list with the following components:
\item{predict}{predicted response values. The dimensions
correspond to the observations, the response variables and the model dimension, respectively. For a supervised model, it corresponds to the predicted dummy variables.}
\item{variates}{matrix of predicted variates.}
\item{B.hat}{matrix of regression coefficients (without the intercept).}

\item{AveragedPredict}{if more than one block, returns the average predicted values over the blocks (using the \code{predict} output)}
\item{WeightedPredict}{if more than one block, returns the weighted average of the predicted values over the blocks (using the \code{predict} and \code{weights} outputs)}

\item{class}{predicted class of \code{newdata} for each \eqn{1,...,}\code{ncomp} components.}

\item{MajorityVote}{if more than one block, returns the majority class over the blocks. NA for a sample means that there is no consensus on the predicted class for this particular sample over the blocks.}
\item{WeightedVote}{if more than one block, returns the weighted majority class over the blocks. NA for a sample means that there is no consensus on the predicted class for this particular sample over the blocks.}
\item{weights}{Returns the weights of each block used for the weighted predictions, for each nrepeat and each fold}

\item{centroids}{matrix of coordinates for centroids.}
\item{dist}{type of distance requested.}
\item{vote}{majority vote result for multi block analysis (see details above).}

}

\references{

Rohart F, Gautier B, Singh A, Lê Cao K-A. mixOmics: an R package for 'omics feature selection and multiple data integration. PLoS Comput Biol 13(11): e1005752


Tenenhaus, M. (1998). \emph{La regression PLS: theorie et pratique}. Paris: Editions Technic.
}

\author{Florian Rohart, Sébastien Déjean, Ignacio González, Kim-Anh Lê Cao}


\seealso{\code{\link{pls}}, \code{\link{spls}}, \code{\link{plsda}}, \code{\link{splsda}},
\code{\link{mint.pls}}, \code{\link{mint.spls}}, \code{\link{mint.plsda}}, \code{\link{mint.splsda}},
\code{\link{block.pls}}, \code{\link{block.spls}}, \code{\link{block.plsda}}, \code{\link{block.splsda}},
\code{\link{mint.block.pls}}, \code{\link{mint.block.spls}}, \code{\link{mint.block.plsda}}, \code{\link{mint.block.splsda}} and visualisation with \code{\link{background.predict}}
and http://www.mixOmics.org for more details.}

\examples{
data(linnerud)
X <- linnerud$exercise
Y <- linnerud$physiological
linn.pls <- pls(X, Y, ncomp = 2, mode = "classic")

indiv1 <- c(200, 40, 60)
indiv2 <- c(190, 45, 45)
newdata <- rbind(indiv1, indiv2)
colnames(newdata) <- colnames(X)
newdata

pred <- predict(linn.pls, newdata)

plotIndiv(linn.pls, comp = 1:2, rep.space = "X-variate",style="graphics",ind.names=FALSE)
points(pred$variates[, 1], pred$variates[, 2], pch = 19, cex = 1.2)
text(pred$variates[, 1], pred$variates[, 2],
c("new ind.1", "new ind.2"), pos = 3)

## First example with plsda
data(liver.toxicity)
X <- liver.toxicity$gene
Y <- as.factor(liver.toxicity$treatment[, 4])


## if training is perfomed on 4/5th of the original data
samp <- sample(1:5, nrow(X), replace = TRUE)
test <- which(samp == 1)   # testing on the first fold
train <- setdiff(1:nrow(X), test)

plsda.train <- plsda(X[train, ], Y[train], ncomp = 2)
test.predict <- predict(plsda.train, X[test, ], dist = "max.dist")
Prediction <- test.predict$class$max.dist[, 2]
cbind(Y = as.character(Y[test]), Prediction)

\dontrun{
## Second example with splsda
splsda.train <- splsda(X[train, ], Y[train], ncomp = 2, keepX = c(30, 30))
test.predict <- predict(splsda.train, X[test, ], dist = "max.dist")
Prediction <- test.predict$class$max.dist[, 2]
cbind(Y = as.character(Y[test]), Prediction)


## example with block.splsda=diablo=sgccda and a missing block
data(nutrimouse)
# need to unmap Y for an unsupervised analysis, where Y is included as a data block in data
Y.mat = unmap(nutrimouse$diet)
data = list(gene = nutrimouse$gene, lipid = nutrimouse$lipid, Y = Y.mat)
# with this design, all blocks are connected
design = matrix(c(0,1,1,1,0,1,1,1,0), ncol = 3, nrow = 3,
byrow = TRUE, dimnames = list(names(data), names(data)))

# train on 75% of the data
ind.train=NULL
for(i in 1:nlevels(nutrimouse$diet))
ind.train=c(ind.train,which(nutrimouse$diet==levels(nutrimouse$diet)[i])[1:6])

#training set
gene.train=nutrimouse$gene[ind.train,]
lipid.train=nutrimouse$lipid[ind.train,]
Y.mat.train=Y.mat[ind.train,]
Y.train=nutrimouse$diet[ind.train]
data.train=list(gene=gene.train,lipid=lipid.train,Y=Y.mat.train)

#test set
gene.test=nutrimouse$gene[-ind.train,]
lipid.test=nutrimouse$lipid[-ind.train,]
Y.mat.test=Y.mat[-ind.train,]
Y.test=nutrimouse$diet[-ind.train]
data.test=list(gene=gene.test,lipid=lipid.test)

# example with block.splsda=diablo=sgccda and a missing block
res.train = block.splsda(X=list(gene=gene.train,lipid=lipid.train),Y=Y.train,
ncomp=3,keepX=list(gene=c(10,10,10),lipid=c(5,5,5)))
test.predict = predict(res.train, newdata=data.test[2], method = "max.dist")


## example with mint.splsda
data(stemcells)

#training set
ind.test = which(stemcells$study == "3")
gene.train = stemcells$gene[-ind.test,]
Y.train = stemcells$celltype[-ind.test]
study.train = factor(stemcells$study[-ind.test])

#test set
gene.test = stemcells$gene[ind.test,]
Y.test = stemcells$celltype[ind.test]
study.test = factor(stemcells$study[ind.test])

res = mint.splsda(X = gene.train, Y = Y.train, ncomp = 3, keepX = c(10, 5, 15),
study = study.train)

pred = predict(res, newdata = gene.test, study.test = study.test)

data.frame(Truth = Y.test, prediction = pred$class$max.dist)

}
}


\keyword{regression}
\keyword{multivariate}
