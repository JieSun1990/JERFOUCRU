## NOTE ##
# Running EM algorithm for data disaggregationg (have to run Adjust_Overlay.R before to get adjusted FOI values)
# Also need to imputed missing values at each features before running this (indeed, only need Bio_15 and Bio_04)
# Convert ordinary intensive problem (mean of FOI of target = FOI of source) into extensive (sum of FOI of target = FOI of source x pixels of source)
# ------ #

library(sp)
library(raster)
library(rgdal)

cat('===== START [EM_Disaggregate.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/EM_DF/'), showWarnings = TRUE)

# =========== DEFINE OWN FUNCTIONS ===========
Convert_Range <- function(xold, oldrange, newrange){
  # Convert xold value from oldrange [A, B] to new value in newrange [C, D]
  minold <- oldrange[1]
  maxold <- oldrange[2]
  minnew <- newrange[1]
  maxnew <- newrange[2]
  xnew <- (xold - minold) / (maxold - minold) * (maxnew - minnew) + minnew
  return(xnew)
}

create_raster_from_df <- function(dataframe, res = c(5, 5),
                                  crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs",
                                  name = 'rasterdf', savefile = FALSE){
  crs <- crs(crs)
  rasterdf <- rasterFromXYZ(dataframe, res = res, crs = crs)
  if (savefile){
    writeRaster(rasterdf, name, overwrite = TRUE, format = "GTiff")
  }
  return(rasterdf)
}

sum.finite <- function(x){
  return(sum(x[is.finite(x)]))
}

compute.us <- function(u, A){ # formular in page 71 (flowerdew1992)
  # u: ust matrix
  # n: matrix of A or N (in target zone)
  n <- A / rowSums(A) # convert to proportion on source zone
  return(rowSums(u * n))
}

compute.yt <- function(y, A){ # formular in page 71 (flowerdew1992) --> for intensive
  # u: yst matrix
  # n: matrix of A or N (in target zone)
  n <- t(A) / rowSums(t(A)) # convert to proportion on target zone
  return(rowSums(t(y) * n))
}

Logllh.poisson <- function(u, y){
  return(- sum.finite(u) + sum.finite(y * log(u)) - sum.finite(lfactorial(y)))
}

Logllh.normal <- function(u, y){
  y_val <- y[y!=0]
  u_val <- u[u!=0]
  meanu <- mean(u_val)
  sig_sq <- var(u_val) * (length(u_val) - 1) / length(u_val)
  llh <- -1/2 * log(2*pi) - 1/2 * (sig_sq) - 1/(2*sig_sq) * sum.finite((y_val - meanu)^2)
  return(llh)
}

disaggregate_EM <- function(A.s, A.st, X.t, Y.s, max_iter = 10000, tol = 0.0001, type = 'extensive'){ # Based on flowerdew1992
  # Disaggregate Y.s from nsource cells to Y.st having ntarget cells based on covariate A from source and target, and covariate X from target cells
  # Input:
  #   A and X is population and Bio_04 (for instance)
  #   A.s: Matrix (nsource x 1 --> Column vector) of covariate A from source cells (have to know this covariate from source) 
  #   A.st: Matrix (nsource x ntarget) of covariate A from target cells (Noted that sumRows(A.st) == A.s or meanRows(A.st) == A.s based on extensive or intensive)
  #   X.t: Matrix (ntarget x 1 --> Column vector) of covariate X from target cells (dont need to know this covariate from source)
  #   Y.s: Matrix (nsource x 1 --> Column vector) of value y from source cells that want to disaggregate to target cells
  #   type: extensive (sum) - intensive (mean)
  # Output:
  #   y.st: Matrix (nsource x ntarget): of disaggregated values of each target cell based on each source cell --> sum or mean (column) to find final value for each target cell
  #   (Noted that sumRows(y.st) == Y.s or meanRows(y.st) == Y.s based on extensive or intensive)
  
  A.t <- colSums(A.st)
  Intersec <- A.st
  Intersec[Intersec!=0] <- 1
  
  nsource <- length(Y.s)
  ntarget <- length(X.t)
  lamb <- rep(0, ntarget)
  X.unique <- unique(X.t)
  X.duplicated <- unique(X.t[which(duplicated(X.t))])
  
  iter <- 1
  L1 <- 0
  L2 <- 1
  maxDif <- 1
  
  while(iter <= max_iter && maxDif >= tol){
    # E step
    if (iter == 1){
      if (type == 'extensive'){
        y.st <- A.st / A.s * Y.s # initialize based on weight on covariate A (extensive)    
      }else{
        y.st <- Intersec * Y.s # initialize based on weight on covariate A (intensive)
        # y.st <- rnorm( , ) # can initialize based on normal distribution (intensive)    
      }
      L1 <- y.st
      cat('----------- START -----------\nIteration:', iter, '=====\n')
    }else{
      if (type == 'extensive'){
        y.st <- Y.s * u.st / rowSums(u.st) # extensive    
      }else{
        y.st <- u.st + Y.s - apply(u.st, 1, function(x){mean(x[x!=0])}) # intensive with evenly distributed
        y.st <- y.st * Intersec   
      }
      L2 <- y.st
      maxDif <- max(abs(L2 - L1))
      L1 <- L2
      cat('Iteration:', iter, '===== Max Update:', maxDif, '\n')
    }
    
    # M step
    Y.t <- colSums(y.st)
    lamb <- Y.t / A.t
    for (unqval in X.duplicated){
      idx <- which(X.t == unqval)
      lamb[idx] <- sum.finite(Y.t[idx]) / sum.finite(A.t[idx])
    }
    u.st <- t(t(A.st) * lamb)
    iter <- iter + 1
  }
  
  # Last iteration to make sure
  if (type == 'extensive'){
    y.st <- Y.s * u.st / rowSums(u.st) # extensive    
  }else{
    y.st <- u.st + Y.s - apply(u.st, 1, function(x){mean(x[x!=0])}) # intensive with evenly distributed
    y.st <- y.st * Intersec   
  }
  cat('Last Iteration:', iter, '===== Max Update:', maxDif, '\n')
  
  return(y.st)
}

# ============ PROCESS =============
df.Overlay <- readRDS(paste0('Generate/Overlay_DF/', 'Adjusted_Overlay_Study.Rds'))
df.Ft <- readRDS(paste0('Generate/Imputed_DF/', 'Imputed_Features_Study.Rds'))

check <- all(identical(df.Overlay$x, df.Ft$x), identical(df.Overlay$y, df.Ft$y)) # Check if coordinates in 2 dataframe are the same

if (!check){
    cat('Coordinates DO NOT match! --> STOP!!!\n')
    return()
}

cov_names <- colnames(df.Ft)
Ft1 <- df.Ft[[which(cov_names == 'Bio_15')]] # Ft1 is feature that need to have positive correlation with FOI --> Plot Correlation Matrix to find the feature
Ft2 <- df.Ft[[which(cov_names == 'Bio_04')]] # Ft2 is the most important feature that related to the FOI --> run RF model on small set and see variable importance
df.EM <- data.frame(x = df.Ft$x, y = df.Ft$y, 
                    Ft1 = Ft1, Ft2 = Ft2, 
                    FOI = df.Overlay$FOI, Region = df.Overlay$Region)

# currently, impute missing data base on mean (if we dont run imputed by random forest first)
df.EM[[3]][which(is.na(df.EM[[3]]))] <- mean(df.EM[[3]], na.rm = TRUE)
df.EM[[4]][which(is.na(df.EM[[4]]))] <- mean(df.EM[[4]], na.rm = TRUE)

# Rescale and make positive correlation of Bio15 (currently nagative correlation) --> EM need a feature positive correlate
oldrange <- c(min(df.EM[[3]]), max(df.EM[[3]]))
newrange <- c(1, 10)
df.EM[[3]] <- Convert_Range(df.EM[[3]], oldrange, newrange)
df.EM[[3]] <- 11 - df.EM[[3]] # convert from [1, 10] to [10, 1] to make positive correlation

# df.EM[[3]] <- 1/df.EM[[3]] # reverse Bio15 to make positive correlation (2 ways: 1st way is make it reverse to have positive, 2nd way is the above lines)

df.EM <- df.EM[order(df.EM$Region), ]

## Try EM at some specific regions (again use regions index provided by Assign_Regions_For_Adjust_Overlay)
# specific <- c(1, 2, 4, 7, 9, 10, 11, 12, 16, 34) # China
# specific <- c(14, 17, 18, 20, 22, 24, # Nepal
# 8, 13, 15, 19, 21, 23, 25, 26, 27, 28, 41, 42, 45, 46, 47) # India
# df.EM <- df.EM[which(df.EM$Region %in% specific), ]

# --------------- Setup for EM --------------------
region <- unique(df.EM$Region)
npixels <- rep(0, length(region))
for(idx.region in 1 : length(region)){
  re <- region[idx.region]
  npixels[idx.region] <- sum(df.EM$Region == re)
}

# ----- Define A.st matrix (highly correlated covariate values of each cell matrix nsource x ntarget dim)
A.st <- matrix(rep(0, nrow(df.EM) * length(region)), ncol = nrow(df.EM), nrow = length(region))
for(idx in 1 : length(region)){
  re <- region[idx]
  idx.point <- which(df.EM$Region == re)
  A.st[idx, idx.point] <- df.EM[[3]][idx.point]
}

# ----- Define A.s matrix (sum values of highly correlated feature of source matrix nsource x 1 dim)
A.s <- rep(0, length(region))
# find sum values of highly correlated feature in each region
for (idx in 1 : length(region)){
  re <- region[idx]
  A.s[idx] <- sum(df.EM[[3]][which(df.EM$Region == re)])
}

# ----- Define Y.s matrix (FOI of source matrix nsource x 1 dim)
Y.s <- rep(0, length(region))
for (idx in 1 : length(region)){
  re <- region[idx]
  Y.s[idx] <- df.EM$FOI[which(df.EM$Region == re)[1]] * npixels[which(region == re)] # (convert to extensive, if Datatype is extensive)   
}

# ----- Define X.t matrix (Covariate Feature, e.g. Bio_04 of target matrix ntarget x 1 dim)
X.t <- df.EM[[4]]

# ----- Perform EM -----
Datatype <- 'extensive' # extensive: sum of target = source ~~~ intensive: mean of target = source
start_time <- proc.time()
y.st <- disaggregate_EM(A.s, A.st, X.t, Y.s, max_iter = 1500, tol = 0.0000001, type = Datatype)
end_time <- proc.time()
cat('Total processing time:', (end_time - start_time)[[3]]/60, "minutes\n")
# ----- Confirming result -----
if (Datatype == 'intensive'){
  cat('Aggregate on Source (Mean):\n')
  print(apply(y.st, 1, function(x){mean(x[x!=0])})) # intensive
  temp <- y.st * A.st
  temp <- colSums(temp)
  temp <- temp / colSums(A.st)
  # data.disaggregate <- apply(y.st, 2, function(x){mean(x[x!=0])})
  data.disaggregate <- temp
}else{
  cat('Aggregate on Source (Sum):\n')
  print(rowSums(y.st)) # extensive
  data.disaggregate <- colSums(y.st)
}

cat('Values on Source:\n')
print(Y.s) 

rm(y.st, A.st, X.t)

## Save the EM dataframe
df.EM$Disaggregate <- data.disaggregate
df.EM <- df.EM[order(-df.EM$y, df.EM$x), ]

# Check matching coordinates --> just to make sure since df.EM coordinates is made from df.Ft
check <- all(identical(df.EM$x, df.Ft$x), identical(df.EM$y, df.Ft$y)) # Check if coordinates in 2 dataframe are the same
if (!check){
    cat('Coordinates DO NOT match! --> STOP!!!\n')
    return()
}

df.Ft$FOI <- df.EM$Disaggregate
saveRDS(df.Ft, paste0('Generate/EM_DF/', 'EM_Imputed_Features_Study.Rds'))

## Create raster map
# You can create a raster map to visualize the EM FOI values map

cat('===== FINISH [EM_Disaggregate.R] =====\n')
