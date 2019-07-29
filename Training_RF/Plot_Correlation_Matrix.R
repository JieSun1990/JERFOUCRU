# --- NOTE ---
# Plot the correlation matrix between features and FOI. This FOI should be Overlay-Adjusted
# The feature also should be imputed by the random forest method.
# Will check the correlation on 10% - 20% - 30% ... 100% datapoints
# ---------- #

library(ggplot2)
library(corrplot)

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

# Folder <- '/home/ubuntu/Data/Data_RF/'
Folder <- '/home/duynguyen/DuyNguyen/RProjects/OUCRU JE/Data JE/Data_RF/'

df <- readRDS(paste0(Folder, 'AllDF_WP_Imputed_Land.Rds'))

df <- df[names(df)[-which(names(df) == 'WM')]] # dont take these into account
df <- df[names(df)[-which(names(df) == 'UR')]] # dont take Urban/Rural into account
na.df <- is.na(df)
na.pos <- apply(na.df, 1, any)
valid.pos <- as.numeric(which(na.pos == F))

valid.df <- df[valid.pos, ]

rm(na.df, na.pos, valid.pos, df)

portion_vec <- seq(1, 100, 10) / 100 # Run the correlation checking on 10% - 20% - 30% - ... - 100% data points
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
  
  pdf(paste0('corrplot_', portion, '.pdf'))
  corrplot(cormat, col = col(200), type = "upper", tl.col = 'black')
  # corrplot(cormat, type = "upper", order = 'hclust', p.mat = pmat)
  dev.off()
}
