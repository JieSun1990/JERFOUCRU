## NOTE ##
# Simple function to crop the boundary of TIF file within a shapefile boundary
# Crop the TIF file (original downloaded from the internet) within the boundary of regions of interest (ROI)
# Here ROI is the endemic area (or any specific countries) --> Shapefile (SHP form)
## ---- ##

library(raster)
library(rgdal)

cat('===== START [Crop_Boundary_Single_Files.R] =====\n')

# Step 1: Read TIF file and shapefile
LinkTIF <- '~/DuyNguyen/RProjects/OUCRU JE/Figures/[Python] Result Model EM/Rescale_TVT_Once/Land/Endemic_EM_Rescale_Full_Cov_TVT_Once_400_Land.tif'
LinkSHP <- '~/DuyNguyen/RProjects/OUCRU JE/Data JE/FOI Shapefile Full/Indo_Map/gadm36_IDN_1.shp' # Example: This is a Indonesia shapefile

map.origin <- raster(LinkTIF)
shapefile <- readOGR(LinkSHP) 
shapefile <- spTransform(shapefile, crs(map.origin))

# Step 2: Crop extend (need to check if they have same CRS)
map.crop <- crop(map.origin, extent(shapefile))

# Step 3: Match pixels if they lie in shapefile 
map.boundary <- mask(map.crop, shapefile)

# Step 4: Save file (optional)
SaveName <- 'Full_Cov_TVT_Once_400_Land_IDN'
writeRaster(map.boundary, SaveName, format = "GTiff")

cat('===== FINISH [Crop_Boundary_Single_Files.R] =====\n')
