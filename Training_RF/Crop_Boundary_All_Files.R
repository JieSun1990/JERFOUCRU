##### NOTE #####
# Use this file at the 1st step
# Crop boundary of all TIF files within one / many folders
# After cropping --> resample/reproject (to make the same coordinates and same resolution) --> 2nd step
#####

library(raster)
library(rgdal)

Crop_Raster <- function(Folder, endemic_shapefile, suffix_name = 'Cropped', start_id = 0, end_id = 0){
    # INPUT
    #   Folder: Link to the direct folder containing tif (or tiff) files
    #   endemic_shapefile: Shapefile of the boundary want to cutoff
    #   suffix_name: suffix string used to make a new file name after cropping
    #   start_id, end_id: index in a list files in a specific folder that we want to perform cropping to --> set it to 0 (default) if we want to perform to all files
    # OUTPUT
    #   No output (cropping and saving files)
    #   Directly save file into hard drive
    
    Files <- list.files(path = Folder, pattern = paste('*', "", '.*.tif$', sep = ""))
    total <- length(Files)
    cat(paste("Total Files:", total, '\n'))
    
    if (start_id == 0)
        start_id = 1
    if (end_id == 0)
        end_id = total
    
    for (id in start_id : end_id){
        
        cat(paste('Processing File:', id, '/', total, '\n'))
        
        file <- Files[id]
        
        if (file.exists(paste0(strtrim(file, nchar(file) - 4), "_", suffix_name, ".tif"))){
            cat(paste(file, "has already been processed --> SKIP!\n"))
        } else {
            # Read map
            start_time <- proc.time()
            map.origin <- raster(paste(Folder, "/", file, sep =''))
            end_time <- proc.time()
            cat(paste("Load", file, "time:", (end_time - start_time)[[3]], "seconds\n"))
            
            # Crop extent to match with Boundary (must have the same CRS -- already checked)
            start_time <- proc.time()
            map.crop <- crop(map.origin, extent(endemic_shapefile))
            end_time <- proc.time()
            cat(paste("Crop", file, "time:", (end_time - start_time)[[3]], "seconds\n"))
            
            rm(map.origin)
            
            # match pixel within vector regions
            start_time <- proc.time()
            map.endemic <- mask(map.crop, endemic_shapefile)
            end_time <- proc.time()
            cat(paste("Mask", file, "time:", (end_time - start_time)[[3]]/60, "mins\n"))
            
            rm(map.crop)
            
            # Save file
            start_time <- proc.time()
            writeRaster(map.endemic, paste0(strtrim(file, nchar(file) - 4), "_", suffix_name, ".tif"), format = "GTiff")
            end_time <- proc.time()
            cat(paste("Save", file, "time:", (end_time - start_time)[[3]], "seconds\n"))
            
            rm(map.endemic)
        }
    }
}

LinkBoundaryFile <- '~/DuyNguyen/RProjects/OUCRU JE/Data JE/Map_Endemic_v3/Ende_map_feed.shp' # specific to name of boundary shapefile
LinkData <- '~/Downloads/Asia_1km_Population/' # Link to the Head Folder (that can contains subfolders) containing TIF Files

start_time <- proc.time()
boundary.shapefile <- readOGR(LinkBoundaryFile)
end_time <- proc.time()
cat(paste("Load Boundary Shapefile time:", (end_time - start_time)[[3]], "seconds\n"))


Folders <- list.dirs(LinkData)

if (length(Folders) > 1){
    cat(paste("There are", length(Folders) - 1, "folders in the LinkData directory! --> Processing in subfolders!\n--------------------\n"))
    for (index_folders in 2 : length(Folders)){
        cat(paste("Processing on", Folders[index_folders], "\n"))
        Crop_Raster(Folders[index_folders], boundary.shapefile)
        cat("\n--------------------\n")
    }
}else{
    cat(paste("Folder contains only files! --> Processing on", Folders[1], "\n--------------------\n"))
    Crop_Raster(Folders[1], boundary.shapefile)
    cat("\n--------------------\n")
}

cat("########## FINISH ##########\n")
