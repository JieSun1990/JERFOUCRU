## NOTE ##
# This file is used to assign region index of each pixel that will be used to Adjust_Overlay
# Same regions mean same study (meaning that FOI is the same in all pixels that belong to 1 study)
# ------ #

library(sp)
library(raster)

cat('===== START [Assign_Regions_For_Adjust_Overlay.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Overlay_TIF/'), showWarnings = TRUE)
dir.create(file.path('Generate/Overlay_DF/'), showWarnings = TRUE)

# Same region and countries

create_raster_from_df <- function(dataframe, res = c(5, 5),
                                  crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs",
                                  name = 'rasterdf', savefile = FALSE, savepath = 'Generate/Overlay_TIF/'){
  crs <- crs(crs)
  rasterdf <- rasterFromXYZ(dataframe, res = res, crs = crs)
  if (savefile){
    writeRaster(rasterdf, paste0(savepath, name), overwrite = TRUE, format = "GTiff")
  }
  return(rasterdf)
}

Folder <- 'Generate/Imputed_DF/'

df <- readRDS(paste0(Folder, 'Imputed_Features_Study.Rds'))
idx_FOI_column <- which(colnames(df) == 'FOI')
df <- df[, c(1, 2, idx_FOI_column)] # only take the coordinates, and foi column

df$Region <- 0

unique_vec <- unique(df$FOI)
tol <- 0.00000001

# ================= FIND UNIQUE FOI REGIONS ==================
for (idx in 1:length(unique_vec)){
  cat('Assign Region', idx, '\n')
  dif <- df$FOI - unique_vec[idx]
  a <- which(abs(dif) < tol)
  df$Region[a] <- idx
  rm(dif)
  rm(a)
}

# Save dataframe with study index
saveRDS(df, paste0('Generate/Overlay_DF/', 'Coordinates_Index_Study.Rds'))

# =================== SAVE TIF FILES ====================
## Save tif files in order to check which regions is the overlay or non-overlay regions --> the checking process need to be done manually with careful
for (choose in 1:length(unique_vec)){
  cat('Process Region', choose, '\n')
  region.df <- df[which(df$Region == choose),]
  region.df <- region.df[, c(1:3)]
  region.raster <- create_raster_from_df(region.df, name = paste0('Region_', choose), savefile = TRUE)
  rm(region.df)
  rm(region.raster)
}

# ================= EXTRACT SPECIFIC REGIONS ==================
## Extract information in small areas that will be applied EM process (This part maybe useless, just ignore it)
# region <- c(29, 31, 32, 33, 35, 36)
# idx.region <- which(df$Region %in% region)
# region.df <- df[idx.region, ]
# idx.cov <- c(1, 2, which(colnames(region.df) == 'Bio_04'), which(colnames(region.df) == 'Pop_2015'), 
#              which(colnames(region.df) == 'FOI'), which(colnames(region.df) == 'Region'))
# regionEM.df <- region.df[, idx.cov] 
# saveRDS(regionEM.df, 'Taiwan_EM_test.Rds')

cat('===== FINISH [Assign_Regions_For_Adjust_Overlay.R] =====\n')
