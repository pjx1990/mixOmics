#############################################################################################################
# Authors:
#   Florian Rohart, Australian Institute for Bioengineering and Nanotechnology, University of Queensland, Brisbane, QLD.
#   Kim-Anh Le Cao, The University of Queensland, The University of Queensland Diamantina Institute, Translational Research Institute, Brisbane, QLD
#
# created: 25-05-2016
# last modified: 24-08-2016
#
# Copyright (C) 2016
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#############################################################################################################

#---------------------------------------------------
# perf for mint.spls and mint.pls object
#---------------------------------------------------
perf.mint.spls  = perf.mint.pls = function(object,
validation = c("Mfold", "loo"),
folds = 10,
progressBar = FALSE,
...)
{
    stop("Yet to be implemented")
}

# ---------------------------------------------------
# perf for mint.plsda and mint.splsda object
# ---------------------------------------------------
perf.mint.splsda = perf.mint.plsda = function (object,
dist = c("all", "max.dist", "centroids.dist", "mahalanobis.dist"),
auc = FALSE,
progressBar = FALSE,
signif.threshold=0.01,
...
)
{    #-- checking general input parameters --------------------------------------#
    #---------------------------------------------------------------------------#
    
    #------------------#
    #-- check entries --#
    X = object$X
    Y = object$Y
    study = object$study
    ncomp = object$ncomp
    scale = object$scale
    
    keepX = apply(object$loadings$X, 2, function(x){sum(x!=0)})
    
    tol = object$tol
    max.iter = object$max.iter
    
    dist = match.arg(dist, choices = c("all", "max.dist", "centroids.dist", "mahalanobis.dist"), several.ok = TRUE)
    if (any(dist == "all"))
    {
        nmthdd = 3
        dist = c("max.dist", "centroids.dist", "mahalanobis.dist")
    } else {
        nmthdd = length(dist)
    }
    
    if (!is.logical(progressBar))
    stop("'progressBar' must be either TRUE or FALSE")
    
    #-- check significance threshold
    signif.threshold <- .check_alpha(signif.threshold)
    
    #-- end checking --#
    #------------------#
    
    near.zero.var = !is.null(object$nzv) # if near.zero.var was used, we set it to TRUE. if not used, object$nzv is NULL


    # -------------------------------------
    # added: first check for near zero var on the whole data set
    if (near.zero.var == TRUE)
    {
        nzv = nearZeroVar(X)
        if (length(nzv$Position > 0))
        {
            warning("Zero- or near-zero variance predictors.\nReset predictors matrix to not near-zero variance predictors.\nSee $nzv for problematic predictors.")
            X = X[, -nzv$Position, drop=TRUE]
            
            if (ncol(X)==0)
            stop("No more predictors after Near Zero Var has been applied!")
        }
    }
    # and then we start from the X data set with the nzv removed

    prediction.all = class.all = list()
    for(ijk in dist)
    {
        class.all[[ijk]] = matrix(nrow = nrow(X), ncol = ncomp,
        dimnames = list(rownames(X), c(paste0('comp', 1 : ncomp))))
    }

    if(auc)
    {
        auc.mean=list()
        auc.mean.study=list()
    }

    study.specific = global = list()
    for (study_i in 1:nlevels(study)) #LOO on the study factor
    {
        study.specific[[study_i]] =list()
        study.specific[[study_i]]$BER = global$BER = matrix(0,nrow = ncomp, ncol = length(dist),
        dimnames = list(c(paste0('comp', 1 : ncomp)), dist))
        
        study.specific[[study_i]]$overall = global$overall = matrix(0,nrow = ncomp, ncol = length(dist),
        dimnames = list(c(paste0('comp', 1 : ncomp)), dist))
        
        study.specific[[study_i]]$error.rate.class = list()
        for(ijk in dist)
        study.specific[[study_i]]$error.rate.class[[ijk]] = global$error.rate.class[[ijk]] = matrix(0,nrow = nlevels(Y), ncol = ncomp,
        dimnames = list(levels(Y),c(paste0('comp', 1 : ncomp))))

    }
    names(study.specific) =levels(study)
    
    # successively tune the components until ncomp: comp1, then comp2, ...
    for(comp in 1 : ncomp)
    {

        already.tested.X = keepX[1:comp]
        
        
        if (progressBar == TRUE)
        cat("\ncomp",comp, "\n")
               
        #-- set up a progress bar --#
        if (progressBar ==  TRUE)
        {
            pb = txtProgressBar(style = 3)
        } else {
            pb = FALSE
        }
        
        M = nlevels(study)
        names.study = levels(study)
        features = NULL
        prediction.comp = matrix(0, nrow = nrow(X), ncol = nlevels(Y), dimnames = list(rownames(X), levels(Y)))

        class.comp = list()
        for(ijk in dist)
        class.comp[[ijk]] = matrix(0, nrow = nrow(X), ncol = 1)# prediction of all samples for each test.keepX and  nrep at comp fixed
        
        if(auc)
        auc.mean.study[[comp]] = list()

        for (study_i in 1:M) #LOO on the study factor
        {
            if (progressBar ==  TRUE)
            setTxtProgressBar(pb, (study_i-1)/M)
            
            omit = which(study %in% names.study[study_i])
            X.train = X[-omit,]
            Y.train = factor(Y[-omit])
            study.learn.CV = factor(as.character(study[-omit]))
            
            X.test = X[omit, , drop = FALSE] #note: drop is useless as there should always be more than a single sample in a study
            Y.test = Y[omit]
            study.test.CV = factor(as.character(study[omit]))
            
            #---------------------------------------#
            #-- near.zero.var ----------------------#
            if(near.zero.var == TRUE)
            {
                remove.zero = nearZeroVar(X.train)$Position
                
                if (length(remove.zero) > 0)
                {
                    X.train = X.train[, -c(remove.zero),drop = FALSE]
                    X.test = X.test[, -c(remove.zero),drop = FALSE]
                }
            }
            #-- near.zero.var ----------------------#
            #---------------------------------------#
            
            if (progressBar ==  TRUE)
            setTxtProgressBar(pb, (study_i-1)/M)
            
            object.res = mint.splsda(X.train, Y.train, study = study.learn.CV, ncomp = comp,
            keepX = already.tested.X,
            scale = scale, mode = "regression")
            
            test.predict.sw <- predict.mixo_spls(object.res, newdata = X.test, dist = dist, study.test = study.test.CV)
            prediction.comp[omit, match(levels(Y.train),levels(Y))] =  test.predict.sw$predict[, , comp]
            
            for(ijk in dist)
            class.comp[[ijk]][omit,1] =  test.predict.sw$class[[ijk]][, comp] #levels(Y)[test.predict.sw$class[[ijk]][, ncomp]]
            
            
            if (progressBar ==  TRUE)
            setTxtProgressBar(pb, (study_i)/M)
            
            # result per study
            #BER
            study.specific[[study_i]]$BER[comp,] = sapply(test.predict.sw$class, function(x){
            conf = get.confusion_matrix(truth = Y[omit], all.levels = levels(Y), predicted = x[,comp])
            get.BER(conf)
            })
            
            #overall
            study.specific[[study_i]]$overall[comp,] = sapply(test.predict.sw$class, function(x){
                conf = get.confusion_matrix(truth = Y[omit], all.levels = levels(Y), predicted = x[,comp])
                out = sum(apply(conf, 1, sum) - diag(conf)) / length(Y[omit])
            })
            
            #classification for each level of Y
            temp = lapply(test.predict.sw$class, function(x){
                conf = get.confusion_matrix(truth = Y[omit], all.levels = levels(Y), predicted = x[,comp])
                out = (apply(conf, 1, sum) - diag(conf)) / summary(Y[omit])
            })
            for (ijk in dist)
            study.specific[[study_i]]$error.rate.class[[ijk]][,comp] = temp[[ijk]]
            
            #AUC per study
            if(auc)
            {
                data = list()
                data$outcome = Y[omit]
                data$data = prediction.comp[omit, ]
                auc.mean.study[[comp]][[study_i]] = statauc(data)
            }
            
        } # end study_i 1:M (M folds)

        for (ijk in dist)
        {
            #prediction of each samples for each fold and each repeat, on each comp
            class.all[[ijk]][,comp] = class.comp[[ijk]][,1]
        }
        prediction.all[[comp]] = prediction.comp
        
        
        # global results
        #BER
        global$BER[comp,] = sapply(class.comp, function(x){
            conf = get.confusion_matrix(truth = factor(Y), predicted = x)
            get.BER(conf)
        })
        
        #overall
        global$overall[comp,] = sapply(class.comp, function(x){
            conf = get.confusion_matrix(truth = factor(Y), predicted = x)
            out = sum(apply(conf, 1, sum) - diag(conf)) / length(Y)
        })
        
        #classification for each level of Y
        temp = lapply(class.comp, function(x){
            conf = get.confusion_matrix(truth = factor(Y), predicted = x)
            out = (apply(conf, 1, sum) - diag(conf)) / summary(Y)
        })
        for (ijk in dist)
        global$error.rate.class[[ijk]][,comp] = temp[[ijk]]

        #AUC global
        if(auc)
        {
            names(auc.mean.study[[comp]]) = names.study

            data = list()
            data$outcome = Y
            data$data = prediction.comp
            auc.mean[[comp]] = statauc(data)
        }


    } # end comp
    names(prediction.all) = paste0('comp', 1:ncomp)
    
    result = list(study.specific.error = study.specific,
    global.error = global,
    predict = prediction.all,
    class = class.all)
    
    if(auc)
    {
        names(auc.mean) = names(auc.mean.study) = paste0('comp', 1:ncomp)
        result$auc = auc.mean
        result$auc.study = auc.mean.study
    }
    
    if (progressBar == TRUE)
    cat('\n')
    

    # calculating the number of optimal component based on t.tests and the error.rate.all, if more than 3 error.rates(repeat>3)
    if(nlevels(study) > 2 & ncomp >1)
    {
        measure = c("overall","BER")
        ncomp_opt = matrix(NA, nrow = length(measure), ncol = length(dist),
        dimnames = list(measure, dist))

        for (measure_i in measure)
        {
            for (ijk in dist)
            {
                mat.error.rate = sapply(study.specific, function(x){x[[measure_i]][,ijk]})
                ncomp_opt[measure_i, ijk] = t.test.process(t(mat.error.rate), alpha = signif.threshold)
            }
        }
    } else {
        ncomp_opt = NULL
    }

    result$choice.ncomp = ncomp_opt


    # added
    if (near.zero.var == TRUE)
    result$nzvX = nzv$Position
    
    class(result) = c("perf","perf.mint.splsda.mthd")
    result$call = match.call()

    return(invisible(result))
}
