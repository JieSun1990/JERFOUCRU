## NOTE ##
# This file is used to calculated missing proportion of each covariates in a dataframe
# ------ #

rm(list=ls())

Find_NA_Portion <- function(DF){
    # input: DF is a dataframe with many columns (features)
    # output: resultdf is a dataframe having 2 columns: feature names, and their missing NA proportion
    ntotal <- nrow(DF)
    NAPortion <- rep(0, ncol(DF) - 2) # subtract x, y coordinates
    
    for (idx_col in 3:ncol(DF)){
        nna <- sum(is.na(DF[[idx_col]]))
        NAPortion[idx_col - 2] <- nna / ntotal * 100
    }
    
    resultdf <- data.frame(Ft_Names = colnames(DF)[c(-1, -2)], NAPortion = NAPortion)
    return(resultdf)
}

DF <- readRDS('Directory/to/yout/Rds/files.Rds')
NADF <- Find_NA_Portion(DF)
