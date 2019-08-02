# --- NOTE ---
# Plot the correlation matrix between features and FOI. This FOI should be Overlay-Adjusted
# The feature also should be imputed by the random forest method.
# Will check the correlation on 10% - 20% - 30% ... 100% datapoints
# ---------- #

library(ggplot2)
library(corrplot)

cat('===== START [Plot_Correlation_Matrix.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Correlation_Matrix/'), showWarnings = TRUE)

Savepath <- 'Generate/Correlation_Matrix/'

# mat : is a matrix of data
# ... : further arguments to pass to the native R cor.test function
cor.mmtest <- function(mat, ...) {
  mat <- as.matrix(mat)
  n <- ncol(mat)
  p.mat<- matrix(NA, n, n)
  diag(p.mat) <- 0
  for (i in 1:(n - 1)) {
    for (j in (i + 1):n) {
      tmp <- cor.test(mat[, i], mat[, j], ...)
      p.mat[i, j] <- p.mat[j, i] <- tmp$p.value
    }
  }
  colnames(p.mat) <- rownames(p.mat) <- colnames(mat)
  return(p.mat)
}

# ----- PLOT CORRELATION MATRIX BASED ON OVERLAY ADJUSTMENT -------
df.Overlay <- readRDS(paste0('Generate/Overlay_DF/', 'Adjusted_Overlay_Study.Rds'))
df.Ft <- readRDS(paste0('Generate/Imputed_DF/', 'Imputed_Features_Study.Rds'))
check <- all(identical(df.Overlay$x, df.Ft$x), identical(df.Overlay$y, df.Ft$y)) # Check if coordinates in 2 dataframe are the same
if (!check){
    cat('Coordinates DO NOT match! --> STOP!!!\n')
    return()
}
df <- df.Ft
df$FOI <- df.Overlay$FOI
rm(df.Ft, df.Overlay)

# ----- PLOT CORRELATION MATRIX BASED ON EM Disaggregation -------
# Folder <- 'Generate/EM_DF/'
# df <- readRDS(paste0(Folder, 'EM_Imputed_Features_Study.Rds'))

# ----- RUN CORRELATION MATRIX PLOT -----
df <- df[names(df)[-which(names(df) == 'UR')]] # dont take Urban/Rural into account
na.df <- is.na(df)
na.pos <- apply(na.df, 1, any)
valid.pos <- as.numeric(which(na.pos == F))

valid.df <- df[valid.pos, ]

rm(na.df, na.pos, valid.pos, df)

portion_vec <- c(1:10)/10 # sample 10% - 20% ... 100% of pixels to plot --> but the results are quite the same
npix_vec <- round(portion_vec * nrow(valid.df))

for (idx in 1 : length(npix_vec)){
  cat('Processing', idx, '/', length(npix_vec),'\n')
  portion <- portion_vec[idx]
  npix <- npix_vec[idx]
  sub.df <- valid.df[sample(1:nrow(valid.df), npix),3:ncol(valid.df)]
  
  cormat <- cor(sub.df)
  # pmat <- cor.mtest(sub.df)
  # col <- colorRampPalette(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA"))
  col <- colorRampPalette(c("#6D9EC1", "white", "#E46726"))
  
  png(paste0(Savepath, 'corrplot_', portion, '.png'), width = 920, height = 892)
  corrplot(cormat, col = col(200), type = "upper", tl.col = 'black')
  # corrplot(cormat, type = "upper", order = 'hclust', p.mat = pmat)
  dev.off()
}
