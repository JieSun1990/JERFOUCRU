# --- NOTE ---
# Create the reference map to which other maps can be calibrated to
# the SHP FOI map can be suitable for this (but need to convert to raster first)
# ---------- #

library(raster)
library(rgdal)

cat('===== START [Create_Reference_For_Calibrate.R] =====\n')

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

# Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Calibrated/FOI/'), showWarnings = TRUE)

FileMap <- 'Data/Original_FOI_Map/Original_FOI_Rasterize.tif' # raster map which is the result from the QGIS rasterize function
origin <- raster(FileMap)

crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs"
crs <- CRS(crs)

# res = 5x5km, method = 'ngb' --> we assign FOI values a pixel the value of the nearest pixel (temporary)
reference <- projectRaster(origin, crs = crs, res = 5, method = 'ngb') 

savename <- 'FOI_Map_Calibrated'
writeRaster(reference, paste0('Generate/Calibrated/FOI/', savename), overwrite = TRUE, format = "GTiff")

cat('===== FINISH [Create_Reference_For_Calibrate.R] =====\n')