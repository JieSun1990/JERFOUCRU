# NOTE #
# Generate Map (TIF) files from dataframe (From Generate_Cases_Dataframe.R)
# Move to the last line of this file to get more information about which files that this script will save
# Default is only plot the total cases of all agegroup --> take the last file in the folder
# ---- #

library(sp)
library(raster)

cat('===== START [Generate_Cases_Map.R] =====\n')

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!!
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)
# Create folder to store the generated raster result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Cases_TIF/'), showWarnings = TRUE)


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
crs_new <- crs("+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs")

# Read data
# These data is the result after running Generate_Cases_Dataframe.R
LinkData <- 'Generate/Cases/'
ListFiles <- list.files(LinkData)

# Create Map (loop)
# for (i in 1 : length(ListFiles)){
    i <- length(ListFiles) # to generate the total cases of all agegroup
    df <- readRDS(paste0(LinkData, ListFiles[i]))
    rasterdf <- rasterFromXYZ(df, res = c(5, 5), crs = crs_new)
    Namefile = paste0('Generate/Cases_TIF/Cases_', colnames(df)[3])
    writeRaster(rasterdf, Namefile, overwrite = TRUE, format = "GTiff")
# }

cat('===== FINISH [Generate_Cases_Map.R] =====\n')