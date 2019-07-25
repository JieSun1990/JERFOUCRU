# NOTE #
# Generate Map (TIF) files from dataframe (From Generate_Cases_Dataframe.R)
# ---- #

library(sp)
library(raster)

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
LinkData <- '~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Data_Cases/'
ListFiles <- list.files(LinkData)
# Create Map (loop)
# for (i in 1 : length(ListFiles)){
    i <- 101
    df <- readRDS(paste0(LinkData, ListFiles[i]))
    rasterdf <- rasterFromXYZ(df, res = c(5, 5), crs = crs_new)
    Namefile = paste0('Cases_', colnames(df)[3])
    writeRaster(rasterdf, Namefile, overwrite = TRUE, format = "GTiff")
# }
