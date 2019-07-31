## NOTE ##
# Simple function to crop the boundary of TIF file within a shapefile boundary
# Crop the TIF file (original downloaded from the internet) within the boundary of regions of interest (ROI)
# Here ROI is the endemic area (or any specific countries) --> Shapefile (SHP form)
## ---- ##

library(raster)
library(rgdal)

cat('===== START [Crop_Boundary_Single_Files.R] =====\n')

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

# Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Cropped/'), showWarnings = TRUE)

# Step 1: Read TIF file and shapefile
LinkTIF <- 'Data/Downloaded_Data/Pigs/Pigs.tif'
LinkSHP <- 'Data/Shapefile_Endemic/Ende_map_feed.shp' # Example: This is a Indonesia shapefile

map.origin <- raster(LinkTIF)
shapefile <- readOGR(LinkSHP) 
shapefile <- spTransform(shapefile, crs(map.origin))

# Step 2: Crop extend (need to check if they have same CRS)
map.crop <- crop(map.origin, extent(shapefile))

# Step 3: Match pixels if they lie in shapefile 
map.boundary <- mask(map.crop, shapefile)

# Step 4: Save file (optional)
SaveName <- 'Cropped_Map'
writeRaster(map.boundary, paste0('Generate/Cropped/', SaveName), format = "GTiff")

cat('===== FINISH [Crop_Boundary_Single_Files.R] =====\n')
