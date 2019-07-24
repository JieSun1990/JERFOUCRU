## NOTE ##
# Used to create raster (TIF) file from CSV (or RDS) file
# Load csv or RDS files to have a dataframe, then run the code to create TIF file (Raster Map) from the dataframe
# Need to check CSV seperate character ("," or "\t")
# ------ #

library(sp)
library(raster)

create_raster_from_df <- function(dataframe, res = c(5, 5),
                                  crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs",
                                  name = 'rasterdf', savefile = FALSE){
    # res is the mapping resolution (km) --> default is 5x5 km
    # savefile = TRUE if we want to save the map to storage
    crs <- CRS(crs)
    rasterdf <- rasterFromXYZ(dataframe, res = res, crs = crs)
    if (savefile){
        writeRaster(rasterdf, name, overwrite = TRUE, format = "GTiff")
    }
    return(rasterdf)
}

Link_file <- '/home/duynguyen/DuyNguyen/PythonProjects/OUCRU_JE/Result with Coor/EM/RescaleTVT_Once/Land/Endemic_result_Full_Cov_TVT_Land_400.csv'
df <- read.csv(Link_file, sep = '\t') # Read CSV --> Can chage to readRDS (if the file is RDS file)

df.map <- df[, c(1, 2, 3)] # only take 3 columns: x, y (2 coordinates column) and the last column will be the values of pixels in the map (Here will be FOI)

Namefile = 'Endemic_EM_Rescale_Full_Cov_TVT_Once_400_Land'
raster <- create_raster_from_df(df.map, name = Namefile, savefile = TRUE)