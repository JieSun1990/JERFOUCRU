# --- NOTE ---
# This script is used to evaluate the accuracy of imputation Random Forest Model
# 1. Extract complete row in a dataframe (complete = no missing values in any column)
# 1.1 Reccommend to run only a part of the entire dataset --> CHANGE numb_of_sample (default is to run only with 1000 pixels)
# 2. Create Pseudo-NA position in the complete dataframe
# 2.1 CHANGE pseudo.na.portion (default is assume 20% of dataframe is missing at each feature )
# 3. Impute these Pseudo-NA by imputation randomf forest model
# 4. Calculate R-square and relative square error to evaluate the accuracy
# ---------- #

library(randomForestSRC)

cat('===== START [Try_Imputation_RF.R] =====\n')

RSE <- function(p, a){
    # p: predicted values
    # a: actual values 
    abar <- mean(a)
    result <- sum((p - a)^2)/sum((a - abar)^2)
    return (result)
}

RSQ <- function(p, a){
    # p: predicted values
    # a: actual values 
    mse <- mean((p - a)^2)
    rsq <- 1 - mse / var(a)
    return (rsq)
}


## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Imputed_DF/'), showWarnings = TRUE)
Savepath <- 'Generate/Imputed_DF/'

# ===== Read the dataframe (before imputed) =====
Folder <- 'Generate/Gathered_DF/'
all <- readRDS(paste0(Folder, 'Original_Features_Endemic.Rds'))

# ===== Remove FOI and Water/Land classification =====
# we dont impute FOI, while Water/Land is already imputed (or we have different imputation for Water/Land)
all$FOI <- NULL
all$WM <- NULL

# ===== Extract complete dataframe =====
all.complete <- all[complete.cases(all), ]
all.complete$UR <- as.factor(all.complete$UR) # set UR is factor
rm(all)

# ===== Try on Small set =====
set.seed(114)
numb_of_sample <- 1000 # only try on small amout of data points
small_idx <- sample(1:nrow(all.complete), numb_of_sample)
all.complete <- all.complete[small_idx,]

# Remove x-y coordinates since we dont impute them, but save them to use later
coord_x <- all.complete$x
coord_y <- all.complete$y
covname <- colnames(all.complete) # store the position of feature names in the dataframe
all.complete$x <- NULL
all.complete$y <- NULL


# ===== PSEUDO NA FOR EACH COVARIATES =====
ntotal <- nrow(all.complete)
pseudo.na.portion <- 50 # percentage of pseudo-na you want to created (20% of entire data)
pseudo.na.nsamples <- round(pseudo.na.portion * nrow(all.complete) / 100) # number of pseudo-na positions at each feature

pseudo.na.list.idx <- list() # store the pseudo NA indexes of each feature
GT.na.list <- list() # store the true values of pseudo NA indexes of each feature
data.pseudo.na <- all.complete # dataframe with pseudo NA values

# sample the pseudo NA indexes in each feature and assign NA values to them
set.seed(113)
for (i in 1 : ncol(all.complete)){ # 26 covariates in the model
    pseudo.na.index <- sample(1:ntotal, pseudo.na.nsamples)
    pseudo.na.list.idx[[i]] <- pseudo.na.index
    GT.na.list[[i]] <- all.complete[[i]][pseudo.na.index]
    data.pseudo.na[[i]][pseudo.na.index] <- NA
}

# ===== IMPUTING =====
ntree <- 500 # number of trees
mtry <- 9 # number of covariates will be used in 1 tree (default is number = covariate / 3) 
nimpute <- 5

cat('Imputing with', pseudo.na.nsamples, 'missing /', ntotal, 'total samples for each feature --- ntree =', ntree, '--- mtry =', mtry, '--- nimpute =', nimpute, '\n')
start_time <- proc.time()
data.impute <- impute(data = data.pseudo.na, ntree = ntree, mtry = mtry, nimpute = nimpute, fast = FALSE)
end_time <- proc.time()
cat(paste("Imputing time:", (end_time - start_time)[[3]]/60, "minutes\n"))

# ===== ANALYZE RESULT =====
# Store the accuracy of imputation RF model
result <- data.frame(name = colnames(all.complete),
                     rsq = 0, rse = 0, 
                     rsqfull = 0, rsefull = 0)
# rsq, rse is rsquare and relative square error on pseudo NA data only
# rsqfull, rsefull is rsquare and relative square error on entire data

for (i in 1 : ncol(all.complete)){
    GT <- GT.na.list[[i]]
    PD <- data.impute[[i]][pseudo.na.list.idx[[i]]]
    GTFull <- all.complete[[i]]
    PDFull <- data.impute[[i]]
    # Since Urban/Rural is a categorical data --> calculate accuracy by percentage classification
    if (colnames(all.complete)[i] != 'UR'){
        result$rsq[i] <- RSQ(PD, GT)
        result$rse[i] <- RSE(PD, GT)
        result$rsqfull[i] <- RSQ(PDFull, GTFull)
        result$rsefull[i] <- RSE(PDFull, GTFull)
    }else{
        dif <- as.numeric(GT) - as.numeric(PD)
        accuracy <- sum(dif == 0) / length(dif)
        diffull <- as.numeric(GTFull) - as.numeric(PDFull)
        accuracyfull <- sum(diffull == 0) / length(diffull)
        result$rsq[i] <- accuracy
        result$rse[i] <- accuracy
        result$rsqfull[i] <- accuracyfull
        result$rsefull[i] <- accuracyfull 
    }
    cat('----- Result of', colnames(all.complete)[i], '-----\n')
    cat('R squared:', result$rsq[i], '\nRelative Square Error:', result$rse[i],'\n')
}

# Assign coordinates back
data.impute$x <- coord_x
data.impute$y <- coord_y
data.impute <- data.impute[,covname]

all.complete$x <- coord_x
all.complete$y <- coord_y
all.complete <- all.complete[,covname]

# ===== Save the Result =====
# Now you can save whatever you want, here I just save result dataframe
# You can also save all.complete or data.impute to create imputed TIF files later
filename <- paste0('Rsq_Imputation_', pseudo.na.portion, '.Rds')
saveRDS(result, paste0(Savepath, filename))

cat('===== FINISH [Try_Imputation_RF.R] =====\n')