# --- NOTE ---
# THIS IS AN EXTREMELY INTENSIVE TASK --> EVEN IF RUNNING ON CLUSTER, IT CAN ALSO CRASH
# Run imputation on entire endemic dataset
# To reduce the work --> we dont use entire dataset to impute --> just a portion of them
# Clearly it can reduce the accuracy of imputation --> but we have no choice --> If we have strong cluster --> can use entire dataset to impute
# ---------- #

library(randomForestSRC)


cat('===== START [Imputation_RF.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Imputed_DF/'), showWarnings = TRUE)
Savepath <- 'Generate/Imputed_DF/'

## ===== Read Gathered DF =====
Folder <- 'Generate/Gathered_DF/'
endemic.original <- readRDS(paste0(Folder, 'Original_Features_Endemic.Rds'))
FOI_column <- endemic.original$FOI
endemic.original$FOI <- NULL # Remove FOI since we dont need it
endemic.original$UR <- as.factor(endemic.original$UR) # set UR is factor
ftname <- colnames(endemic.original)
# Store the coordinates, then remove from the dataframe (we dont use coordinates for anything)
coord_x <- endemic.original$x
coord_y <- endemic.original$y
endemic.original$x <- NULL
endemic.original$y <- NULL

## ===== Find index of rows containing NA and rows that do not contain any NA values =====
complete <- complete.cases(endemic.original)
idx_complete <- which(complete) # idx of rows that do not have NA
idx_na <- which(!complete) # idx of rows that have at least one NA in any column

# Find number of rows
numb_na_rows <- length(idx_na)
numb_cp_rows <- length(idx_complete)
numb_rows <- numb_na_rows + numb_cp_rows # Indeed, numb_rows = nrows(endemic.original)
cat('Total Missing row:', numb_na_rows, '/', numb_rows, '-----', numb_na_rows/numb_rows*100, '%\n')

## ===== Use small portion of complete rows to impute NA rows =====
# This is because it is too intensive to run the imputation if we use all of complete rows
# Here we used the number of complete rows for imputation = 50% of NA rows
# If you want to use entire complete rows --> Change the following line to numb_cp_rows
numb_cp_rows_for_imputation <- round(0.5 * numb_na_rows) 
set.seed(118)
idx_complete_sample <- idx_complete[sample(1:numb_cp_rows, numb_cp_rows_for_imputation)]
idx_choose <- c(idx_na, idx_complete_sample)
endemic.runimpute <- endemic.original[idx_choose, ]
numb_rows_impute <- nrow(endemic.runimpute)

idx_all <- c(1:numb_rows)
idx_not_choose <- which(!idx_all %in% idx_choose)

# ===== IMPUTING =====
ntree <- 500 # number of trees
mtry <- 9 # number of covariates will be used in 1 tree (default is number = covariate / 3) 
nimpute <- 5
cat('Imputing with', numb_na_rows, 'missing /', numb_rows_impute, 'total rows --- ntree =', ntree, '--- mtry =', mtry, '--- nimpute =', nimpute, '\n')

start_time <- proc.time()
data.impute <- impute(data = endemic.runimpute, ntree = ntree, mtry = mtry, nimpute = nimpute, fast = FALSE)
end_time <- proc.time()
cat(paste("Imputing time:", (end_time - start_time)[[3]]/60, "minutes\n"))

# ===== Assign coordinates again =====
data.impute$x <- coord_x[idx_choose]
data.impute$y <- coord_y[idx_choose]
data.impute$FOI <- FOI_column[idx_choose]
data.impute <- data.impute[, ftname]

if (numb_rows_impute != numb_rows){
    # Extract data that does not include in the imputation step and bind with imputed data to re-created Endemic data
    data.notimpute <- endemic.original[idx_not_choose, ]
    data.notimpute$x <- coord_x[idx_not_choose]
    data.notimpute$y <- coord_y[idx_not_choose]
    data.notimpute$FOI <- FOI_column[idx_not_choose]
    data.notimpute <- data.notimpute[, ftname]
    endemic.imputed <- rbind(data.impute, data.notimpute)
}else{
    endemic.imputed <- data.impute # This case is when you use entire complete rows to impute --> data.impute is entire Endemic data
}
endemic.imputed <- endemic.imputed[order(-endemic.imputed$y, endemic.imputed$x), ]

# ===== Save =====
filename <- 'Imputed_Features_Endemic.Rds'
saveRDS(endemic.imputed, paste0(Savepath, filename))

cat('===== FINISH [Imputation_RF.R] =====\n')