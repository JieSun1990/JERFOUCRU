##### NOTE #####
# Perform Calibrate process for entire files in a folder (including its subfolders)
## used to convert raster B to the same resolution, same coordinates and same CRS with the reference raster A 
# km / 40000 * 360 = degree --> 0.00833 deg = 1km = 30 seconds (GOOGLE TO CONFIRM)
# ProjectRaster: https://www.rdocumentation.org/packages/raster/versions/2.9-23/topics/projectRaster
# Aggregate: https://www.rdocumentation.org/packages/raster/versions/2.9-5/topics/aggregate
# Resample: https://www.rdocumentation.org/packages/raster/versions/2.9-23/topics/resample

# Procedure: Project --> Aggregate --> Resample
# ** projectRaster: reproject original raster into new CRS, can change the resolution (but keep it as original is better, we will change in aggregate function later)
# ** projectRaster: the resolution in projected raster is defined from new CRS (check manually the corresponding values: 0.00833 degree = 1km = 30 seconds)
# ** aggregate: aggregate from small resolution (1x1km) into higher resolution (5x5km) --> factor number = 5km / 1km = 5
# ** resample: last step to make sure new raster will have the same coordinates with the original raster
################

library(raster)
library(rgdal)
library(sp)

cat('===== START [Calibrate_Raster_All_Files.R] =====\n')

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

# Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Calibrated/'), showWarnings = TRUE)

agg.fun <- function(x, ...){
    return(sum(x))
}

Reproject_Aggregate <- function(origin, crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs",
                                method_reproject = 'bilinear', method_aggregate = 'bilinear', res_reproject = 1, res_aggregate = 5){
    # Project raster Origin to the given CRS (just for make sure, since we have already done it in Crop step) and convert original resolution from old CRS into corresponding resolution in new CRS
    # Need to check res_reproject manually before running this script
    # res is a numeric number (resolution in km)
    # method = 'ngb' --> nearest neighbor --> category data
    # method = 'bilinear' --> bilinear regression --> continuous data
    # method = 'sum' --> for aggregate number of people (take sum) --> only for AGGREGATE FUNCTION
    
    crs_real <- CRS(crs)
    if (method_reproject == 'sum')
        method_reproject <- 'bilinear'
    map.projected <- projectRaster(origin, crs = crs_real, res = res_reproject, method = method_reproject)
    factor_resolution <- as.integer(res_aggregate / res_reproject) # Aggregation factor expressed as number of cells in each direction
    if (res_aggregate < res_reproject){ # if the original projected resolution is higher than aggregate resolution --> cant aggregate --> keep it there
        map.aggregate <- projectRaster(map.projected, crs = crs_real, res = res_aggregate, method = method_reproject)
    }else{
        if (method_aggregate == 'sum'){
            map.aggregate <- aggregate(map.projected, fact = factor_resolution, fun = agg.fun, expand = TRUE, na.rm = TRUE)
        }else{
            if (method_aggregate == 'bilinear'){
                map.aggregate <- aggregate(map.projected, fact = factor_resolution, fun = mean, expand = TRUE, na.rm = TRUE)    
            }else{
                map.aggregate <- aggregate(map.projected, fact = factor_resolution, fun = modal, expand = TRUE, na.rm = TRUE)    
            }
        }    
    }
    
    return(map.aggregate)
    
}

Resample_Raster <- function(origin, reference, method = 'bilinear', savefile = TRUE, savename = "Temp_Resample", Save_path = 'Generate/Calibrated/'){
    # method = 'ngb --> nearest neighbor --> category data
    # method = 'bilinear' --> bilinear regression --> continuous data
    # Save_path: Directory to the folder where you want to save the cropped maps to
    
    resample <- resample(origin, reference, method = method)
    
    check_1 <- all.equal(extent(resample), extent(reference)) 
    check_2 <- identical(res(resample), res(reference))
    
    if (check_1 == TRUE && check_2 == TRUE){
        cat("Resample successfully --> Match criteria to be saved --> Can save file\n")
        if (savefile == TRUE){
            cat("savefile parameter is TRUE --> SAVING ... \n")
            writeRaster(resample, paste0(Save_path, savename), overwrite = TRUE, format = "GTiff")
            cat("DONE SAVING!\n")
        }else{
            cat("savefile parameter is FALSE --> DONT SAVE!\n")
        }
    }else{
        cat("WARNING: Criteria do not satisfy! --> Resample failed! --> DO NOT SAVE FILE\n")
    }
    
    return(resample)
}

Calibrate_Raster <- function(origin, reference, 
                             crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs",
                             method_reproject = 'bilinear', method_aggregate = 'bilinear', res_reproject = 1, res_aggregate = 5,
                             savefile = TRUE, savename = 'Temp_Calibrate'){
    # Calibrate origin raster to match with reference raster procedure: reproject --> aggregate --> resample
    # method of resample will be the same with method_reproject
    
    aggregate <- Reproject_Aggregate(origin = origin, crs = crs, method_reproject = method_reproject, method_aggregate = method_aggregate,
                                     res_reproject = res_reproject, res_aggregate = res_aggregate)
    calibrate <- Resample_Raster(origin = aggregate, reference = reference, 
                                method = method_reproject, savefile = savefile, 
                                savename = savename)
    return(calibrate)
}

# Script to perform on entire files in a folder
Calibrate_Raster_Folder <- function(Folder, reference,
                                    method_reproject = 'bilinear', method_aggregate = 'bilinear', 
                                    res_reproject = 1, res_aggregate = 5){
    # Process Resample_Raster on entire files in a Folder
    # method of resample will be the same with method_reproject
    # Calibrate all rasters in a Folder and save it 
    
    crs <- "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs" # DO NOT CHANGE THIS CRS
    
    Files <- list.files(path = Folder, pattern = paste('*', "", '.*.tif$', sep = ""))
    total <- length(Files)
    cat(paste("Total Files:", total, '\n'))
    
    for (id in 1 : total){
        cat(paste('Processing File:', id, '/', total, '\n'))
        file <- Files[id]
        origin <- raster(paste0(Folder, "/", file))
        
        start_time <- proc.time()
        calirate <- Calibrate_Raster(origin = origin, reference = reference, crs = crs, 
                                     method_reproject = method_reproject, method_aggregate = method_aggregate,
                                     res_reproject = res_reproject, res_aggregate = res_aggregate,
                                     savefile = TRUE, savename = paste0(strtrim(file, nchar(file) - 4), "_Calibrate"))
        end_time <- proc.time()
        cat(paste("Processing Time on", file, ":", (end_time - start_time)[[3]], "seconds\n"))
    }
}

# EXAMPLE TO PERFORM FOR ENTIRE FOLDERS
# Listmethod: 1 --> ngb, 2 --> bilinear, 3 --> sum
# Note that Method_Aggregate for Population need to be 3: sum
WholeData <- 'Generate/Cropped/'
ListData <- c('Pigs/', 'Bioclimate/') # List subfolders in WholeData
ListResolution_Reproject <- c(5, 1) # integer in km x km (original convert from CRS: 0.00833 deg = 1km = 30 seconds)
ListMethod_Reproject <- c(2, 2) # possible value: 1, 2
ListMethod_Aggregate <- c(2, 2) # possible value: 1, 2, 3

FileRef <- '/home/ubuntu/Data/WaterMask_Resample/Water_Mask_Endemic_v3_Resample.tif'
Ref.resample <- raster(FileRef)


ListMethod_Reproject[ListMethod_Reproject == 1] <- 'ngb'
ListMethod_Reproject[ListMethod_Reproject == 2] <- 'bilinear'

ListMethod_Aggregate[ListMethod_Aggregate == 1] <- 'ngb'
ListMethod_Aggregate[ListMethod_Aggregate == 2] <- 'bilinear'
ListMethod_Aggregate[ListMethod_Aggregate == 3] <- 'sum'

for (index_Data in 1 : length(ListData)){
    Data <- ListData[index_Data]
    Method_Reproject <- ListMethod_Reproject[index_Data]
    Method_Aggregate <- ListMethod_Aggregate[index_Data]
    Res_Reproject <- ListResolution_Reproject[index_Data]
    LinkData <- paste(WholeData, Data, sep = '')
    Folders <- list.dirs(LinkData)
    
    if (length(Folders) > 1){
        cat(paste("There are", length(Folders) - 1, "folders in the LinkData directory! --> Processing in subfolders!\n--------------------\n"))
        for (index_folders in 2 : length(Folders)){
            cat(paste("Processing on", Folders[index_folders], "\n"))
            
            Calibrate_Raster_Folder(Folder = Folders[index_folders], reference = Ref.resample, 
                                    method_reproject = Method_Reproject, method_aggregate = Method_Aggregate,
                                    res_reproject = Res_Reproject, res_aggregate = 5)
            
            cat("\n--------------------\n")
        }
    }else{
        cat(paste("Folder contains only files! --> Processing on", Folders[1], "\n--------------------\n"))
        
        Calibrate_Raster_Folder(Folder = Folders[index_folders], reference = Ref.resample, 
                                method_reproject = Method_Reproject, method_aggregate = Method_Aggregate,
                                res_reproject = 1, res_aggregate = 5)
        
        cat("\n--------------------\n")
    }    
}

cat('===== FINISH [Calibrate_Raster_All_Files.R] =====\n')
