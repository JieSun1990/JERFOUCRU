# --- NOTE ---
# This script is used to create Sampling Grids
# We will divided into 3 subset (Train-Validate-Test) based on these Sampling Grids
# Note that we train - validate - test the RF model on the dataset that already had the FOI values
# After we finish the RF model, we will predict FOI at pixel we dont have FOI
# ---------- #

library(sp)
library(raster)
library(rgdal)
# library(rasterVis)
# library(latticeExtra)

cat('===== START [Create_Sampling_Grids.R] =====\n')

# Create Grid for sampling samples

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


myseq <- function(from, to, step){
    # generate sequence from to by step with a specific constraint --> dont allow a last element too different with other
    # normal seq(1, 6, 1.5) --> 1 2.5 4 5.5 --> last difference is 6 - 5.5 = 0.5 (large margin)
    # myseq(1, 6, 1.5) --> 1 2.5 4 --> last difference is 6 - 4 = 2 (reasonable margin)
    my_vec <- seq(from, to, step)
    last <- my_vec[length(my_vec)]
    dif <- to - last
    if (dif < 0.5 * step){
        my_vec <- my_vec[-length(my_vec)]    
    }
    return(my_vec)
}

createGrid <- function(extentGrid, resGrid){
    seqx <- myseq(extentGrid[1], extentGrid[2], resGrid[1])
    seqy <- myseq(extentGrid[3], extentGrid[4], resGrid[2])
    nGrid <- length(seqx) * length(seqy)
    dataGrid <- data.frame(matrix(NA, nrow = nGrid, ncol = 4))
    colnames(dataGrid) <- c('xmin', 'xmax', 'ymin', 'ymax')
    seqx <- c(seqx, extentGrid[2])
    seqy <- c(seqy, extentGrid[4])
    index <- 1
    
    cat('Creating', nGrid, 'Grids with resolution of', resGrid[1], 'x', resGrid[2], 'km ... \n')
    
    for (idy in (1 : (length(seqy)-1))){
        for (idx in(1 : (length(seqx)-1))){
            dataGrid[index, 1] <- seqx[idx]
            dataGrid[index, 2] <- seqx[idx + 1]
            dataGrid[index, 3] <- seqy[idy]
            dataGrid[index, 4] <- seqy[idy + 1]
            index <- index + 1
        }
    }
    return(dataGrid)
}

assignGrid <- function(dataframe, dataGrid){
    dataframe$Grid <- 0
    nGrid <- nrow(dataGrid)
    portion_vec <- round(seq(1, nGrid, length.out = 11))
    portion_vec <- portion_vec[-1]
    
    cat('Assigning Grid number for entire cells in the map with', nGrid, 'Grids ...\n')
    
    for (idx in 1:nGrid){
        
        if(idx %in% portion_vec){
            cat('Done Grid', idx, '...\n')    
        }
        
        lim <- as.numeric(dataGrid[idx,])
        cond.xmin <- dataframe$x > lim[1]
        cond.xmax <- dataframe$x < lim[2]
        cond.ymin <- dataframe$y > lim[3]
        cond.ymax <- dataframe$y < lim[4]
        cond.all <- cond.xmin & cond.xmax & cond.ymin & cond.ymax
        idGrid <- which(cond.all)
        dataframe$Grid[idGrid] <- idx
    }
    
    return(dataframe)
}

# Take extent of a Calibrated map (use extent to limit xmax, xmin, ymax, ymin coordinates)
MapFOI <- raster('/home/duynguyen/DuyNguyen/RProjects/OUCRU JE/Data JE/Data_Resample_v3/FOI/Adjusted_FOI_Map_Endemic_v3_Resample.tif')
extentMap <- extent(MapFOI)
rm(MapFOI)

# Take the coordinates of all pixels that contain FOI values (we dont take pixels do not have FOI into account)
dataframe <- readRDS('/home/duynguyen/DuyNguyen/RProjects/OUCRU JE/Data JE/Data_RF/AllDF_Adjusted_WP_Land_Imputed_Land.Rds')
dataframe <- dataframe[, c(1,2)]
dataframe$Grid <- 0

xmin <- extentMap@xmin
xmax <- extentMap@xmax
ymin <- extentMap@ymin
ymax <- extentMap@ymax
extentGrid <- c(xmin, xmax, ymin, ymax)
resolution_vec <- c(200, 300, 400, 500) # Resolution of 1 grid (in kilometers)
for (idx_resolution in 1 : length(resolution_vec)){
    resolution <- resolution_vec[idx_resolution]
    cat('Grid resolution (km):', resolution, ' x ', resolution, '\n')
    resGrid <- c(resolution, resolution) # Ex:resolution of grid 500km x 500km
    dataGrid <- createGrid(extentGrid, resGrid)
    dataframe_grid <- assignGrid(dataframe, dataGrid)
    # Check how many grids / valid grids created
    # valid grids are grids containing pixels in it (some Grids are blank - no pixel lies inside)
    n_all_grid <- nrow(dataGrid)
    valid_grid <- unique(dataframe_grid$Grid)
    n_valid_grid <- length(valid_grid)
    cat('Total Valid Grids:', n_valid_grid, '/ Total Grids:', n_all_grid, '\n==========\n')
    # Save grid into csv file so that Python can read it
    write.csv(dataframe_grid, paste0('Grid_', resolution, '_', resolution, '.csv'), row.names = FALSE)
}

# ----- Plot randomly -----
# data.choose <- dataframe[which(dataframe$Grid == 1900), ]
# data.choose$Grid <- 9999
# 
# raster.all <- create_raster_from_df(dataframe)
# raster.choose <- create_raster_from_df(data.choose)
# # spplot(raster.all) + as.layer(spplot(raster.choose), under = TRUE)
# plot(raster.all, col = 'green', legend = FALSE)
# plot(raster.choose, col = 'red', legend = FALSE, add = TRUE)

cat('===== FINISH [Create_Sampling_Grids.R] =====\n')
