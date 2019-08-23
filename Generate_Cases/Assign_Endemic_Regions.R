# NOTE #
# Assign regions of SHP Endemic area to each pixel of FOI result
# For pixel that is not inside SHP file (at edges) --> labels as the nearest pixel
# ---- #

library(sp)
library(raster)
library(rgdal)

cat('===== START [Assign_Endemic_Regions.R] =====\n')

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!!
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

# Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate'), showWarnings = TRUE)

# # Read FOI Map file <-- Result after running Randomforest
df.csv <- read.csv('Data/Endemic_result_Full_Cov_TVT_Land_400.csv', sep = '\t')
df.csv <- df.csv[, -1]
df.foi <- df.csv[, c(1, 2)]
rm(df.csv)

# Read SHP File of endemic area <-- Shapefile that indicates the endemic areas
region.shp <- readOGR('Data/Shapefile_Endemic/Ende_map_feed.shp')
countries <- region.shp@data$Country
countries <- as.character(countries) # countries in endemic areas

# Assign regions (countries) index for each pixel
mycrs <- CRS("+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs")
df.foi$regions <- 0
for (i in 1 : length(countries)){
    country <- countries[i]
    cat('Assigning:', country, '\n')
    idx_valid <- which(df.foi$regions == 0)
    point <- df.foi[idx_valid, c(1,2)]
    coordinates(point) <- ~ x + y
    proj4string(point) <- mycrs
    region <- region.shp[i, ]
    region <- spTransform(region, mycrs)
    point.in.geography <- over(point, region)
    idx.region <- which(!is.na(point.in.geography$Country))
    df.foi$regions[idx_valid[idx.region]] <- i
}

# For pixels that lie on the edge of shapefile --> the above function wont process --> index is still 0 --> nearest neighbor assigning process
idx_non_regions <- which(df.regions$regions == 0)
if(length(idx_non_regions) > 0){
    idx_regions <- which(df.regions$regions != 0)
    df.valid <- df.regions[idx_regions, c(1, 2)]
    df.invalid <- df.regions[idx_non_regions, c(1, 2)]
    for (i in 1 : nrow(df.invalid)){
        point <- as.numeric(df.invalid[i, ])
        t1 <- df.valid[,1] - point[1]
        t2 <- df.valid[,2] - point[2]
        t <- sqrt(t1^2 + t2^2)
        idx_near <- which(t == min(t))
        if (length(idx_near) == 1){
            df.regions$regions[idx_non_regions[i]] <- df.regions$regions[idx_regions[idx_near]]
        }else{
            dif <- abs(idx_near - idx_non_regions[i])
            idx_near <- idx_near[which(dif == min(dif)[1])]
            df.regions$regions[idx_non_regions[i]] <- df.regions$regions[idx_regions[idx_near]]
        }
    }
}
saveRDS(df.foi, 'Generate/Coord_Regions_Final.Rds') # index of each pixel (dataframe with 3 columns: x, y (coordinates), regions (index))
saveRDS(countries, 'Generate/Country_Index.Rds') # label of index (index = 1 --> country 'AUS', ...)

cat('===== FINISH [Assign_Endemic_Regions.R] =====\n')