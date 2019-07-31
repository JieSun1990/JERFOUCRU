##### NOTE #####
# Perform Calibrate process to a single file for trying
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

cat('===== START [Calibrate_Raster_Single_File.R] =====\n')

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


# EXAMPLE TO PERFORM FOR 1 FILE
# Set up
FileOrigin <- 'Generate/Cropped/Pigs/Pigs.tif' # Example
Origin <- raster(FileOrigin)

FileRef <- '/home/ubuntu/Data/WaterMask_Resample/Water_Mask_Endemic_v3_Resample.tif'
Ref.resample <- raster(FileRef)

crs <- "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs" # DO NOT CHANGE THIS CRS

Resolution_reproject <- 1 # need to check manualy
Resolution_resample <- 5 # always 5 as we want to create a map with 5x5km resolution

Method_reproject <- 'bilinear' # Because pigs density is a continuous values
Method_aggregate <- 'bilinear' # Change to 'sum' if the covariate is population. Because the population of bigger resolution = sum of all population of smaller pixel within the large resolution

# Perform the process
start_time <- proc.time()
calirate <- Calibrate_Raster(origin = Origin, reference = Ref.resample, crs = crs, 
                             method_reproject = Method_reproject, method_aggregate = Method_aggregate,
                             res_reproject = Res_reproject, res_aggregate = Res_aggregate,
                             savefile = TRUE, savename = "Calibrated_Map")
end_time <- proc.time()
cat(paste("Processing Time:", (end_time - start_time)[[3]], "seconds\n"))




cat('===== FINISH [Calibrate_Raster_Single_File.R] =====\n')
