# --- NOTE ---
# This script is used to adjust the overlay issue
# Run this file after running Assign_Regions_For_Adjust_Overlay.R script
# 4 countries that need to be adjusted is China, SKorea, Nepal, India
# Since some catchment areas in these countries is including smaller catchment areas --> need to adjust them
# ---------- #

library(sp)
library(raster)
library(rgdal)

cat('===== START [Adjust_Overlay.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

df.origin <- readRDS(paste0('Generate/Overlay_DF/', 'Coordinates_Index_Study.Rds'))

SHPPath <- 'Data/Shapefile_Overlay/'
SHPPath_India <- paste0(SHPPath, 'India_Map/')
SHPPath_Nepal <- paste0(SHPPath, 'Nepal_Map/')

countries <- list(c(1, 2, 4, 7, 9, 10, 11, 12, 16, 34), # CHINA --> Adjust
                  c(29, 31, 32, 33, 35, 36), # Taiwan
                  c(43), # Cambodia
                  c(37, 40), # Vietnam
                  c(3), # Japan
                  c(39), # Laos
                  c(5, 6), # SKOREA --> Adjust
                  c(38), # Philippines
                  c(44), # Thaiand
                  c(49), # Malaysia
                  c(14, 17, 18, 20, 22, 24), # NEPAL --> Adjust
                  c(50, 51), # Indonesia
                  c(8, 13, 15, 19, 21, 23, 25, 26, 27, 28, 41, 42, 45, 46, 47), # INDIA --> Adjust
                  c(30), # Bangladesh
                  c(48)) # SriLanka
names(countries) <- c('China', 'Taiwan', 'Cambodia', 'Vietnam', 'Japan', 'Laos', 'SKorea', 
                      'Philippines', 'Thailand', 'Malaysia', 'Nepal', 'Indonesia',
                      'India', 'Bangladesh', 'SriLanka')

needadjust <- c('China', 'SKorea', 'Nepal', 'India')
mycrs <- CRS("+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs")

for(country.needadjust in needadjust){
  cat('Adjusting', country.needadjust, '...\n')
  region <- countries[[country.needadjust]]
  idx <- which(df.origin$Region %in% region)
  df.country <- df.origin[idx, ]
  rm(idx)
  
  # find number of pixels in each sub regions (based on dataframe)
  npixels <- rep(0, length(region))
  for(idx.region in 1 : length(region)){
    re <- region[idx.region]
    npixels[idx.region] <- sum(df.country$Region == re)
  }
  
  FOI.old <- c()
  for (re in region){
    FOI.old <- c(FOI.old, df.country$FOI[which(df.country$Region == re)[1]])    
  }
  FOI.new <- FOI.old
  npixels.sum <- npixels
  
  # ===== Specific to each countries =====
  
  # --------------- Adjust for China ---------------
  if(country.needadjust == 'China'){
    # find a real number of pixels in each sub regions (based on map and overlay info)
    npixels.sum[which(region == 2)] <- sum(npixels) # region 2 is the based of all sub regions 
    npixels.sum[which(region == 1)] <- npixels[which(region == 1)] + npixels[which(region == 4)] + 
      npixels[which(region == 7)] + npixels[which(region == 9)] +
      npixels[which(region == 10)] + npixels[which(region == 11)] + 
      npixels[which(region == 16)] + npixels[which(region == 34)] # 1 --> 4, 7, 9, 10, 11, 16, 34
    
    # Adjust FOI for overlaped sub regions (eg 1, 2)
    FOI.total <- FOI.old * npixels.sum
    FOI.new[which(region == 1)] <- (FOI.total[which(region == 1)] - FOI.total[which(region == 4)] - FOI.total[which(region == 7)] - 
                                      FOI.total[which(region == 9)] - FOI.total[which(region == 10)] - FOI.total[which(region == 11)] - 
                                      FOI.total[which(region == 16)] - FOI.total[which(region == 34)]) / npixels[which(region == 1)]
    FOI.new[which(region == 2)] <- (FOI.total[which(region == 2)] - FOI.total[which(region == 1)] - FOI.total[which(region == 12)]) / npixels[which(region == 2)]
  }
  
  # --------------- Adjust for SKorea ---------------
  if(country.needadjust == 'SKorea'){
    npixels.sum[which(region == 5)] <- sum(npixels) # 5 --> 6
    FOI.total <- FOI.old * npixels.sum
    FOI.new[which(region == 5)] <- (FOI.total[which(region == 5)] - FOI.total[which(region == 6)])/npixels[which(region == 5)]
  }
  
  # --------------- Adjust for Nepal ---------------
  if(country.needadjust == 'Nepal'){
    SHPNames <- c('non.kathmandu', 'non.W.Terai', 'W.Terai', 'Kosi.zone', 'Chitwan', 'kathmandu') # SHPNames has to be respective to region
    point <- df.country[, c(1,2)] 
    coordinates(point) <- ~ x + y
    proj4string(point) <- mycrs
    idx.shp <- which(SHPNames == 'non.kathmandu')
    idx.point <- which(df.country$Region == 20) # point in Kosi.zone
    region.shp <- readOGR(paste0(SHPPath_Nepal, SHPNames[idx.shp], '.shp'))
    region.shp <- spTransform(region.shp, mycrs) 
    point.in.non.kathmandu <- over(point[idx.point], region.shp)
    point.in.non.kathmandu <- sum(!is.na(point.in.non.kathmandu$FOI_val))
    point.in.non.W.Terai <- npixels[which(region == 20)] - point.in.non.kathmandu
    
    npixels.sum[which(region == 14)] <- npixels.sum[which(region == 14)] + point.in.non.kathmandu # Adjust non.kathmandu
    npixels.sum[which(region == 17)] <- npixels.sum[which(region == 17)] + npixels.sum[which(region == 22)] + 
      point.in.non.W.Terai # Adjust non.W.Terai
    
    FOI.total <- FOI.old * npixels.sum
    FOI.new[which(region == 14)] <- (FOI.total[which(region == 14)] - 
                                       point.in.non.kathmandu * FOI.new[which(region == 20)]) / npixels[which(region == 14)] # Adjust non.kathmandu
    FOI.new[which(region == 17)] <- (FOI.total[which(region == 17)] - FOI.total[which(region == 22)] - 
                                       point.in.non.W.Terai * FOI.new[which(region == 20)]) / npixels[which(region == 17)] # Adjust non.W.Terai
  }
  
  # --------------- Adjust for India ---------------
  if(country.needadjust == 'India'){
    # find a real number of pixels in each sub regions (based on map and overlay info)
    SHPNames <- c('India', 'uttar', '7up.dist.assam', 'N.uttar', 'assam', 'dhemaji', 'gorakhpur.div', 'kushinagar', '
                  N.westbegal', 'gorakhpur.dist', 'bellary.neighbor', 'bellary', 'tamilnadu', 'pondicherry', 'cuddalore') # SHPNames has to be respective to region
    point <- df.country[, c(1,2)] 
    coordinates(point) <- ~ x + y
    proj4string(point) <- mycrs
    
    npixels.sum[which(region == 8)] <- sum(npixels) # region 8 is the based of all sub regions
    
    npixels.sum[which(region == 13)] <- npixels[which(region == 13)] + npixels[which(region == 19)] +  # Adjust uttar
      npixels[which(region == 25)] + npixels[which(region == 26)] + npixels[which(region == 28)]
    npixels.sum[which(region == 19)] <- npixels[which(region == 19)] + npixels[which(region == 28)] # Adjust N.uttar
    npixels.sum[which(region == 25)] <- npixels[which(region == 25)] + npixels[which(region == 28)] + npixels[which(region == 26)] # Adjust gorakhpur.div
    npixels.sum[which(region == 41)] <- npixels[which(region == 41)] + npixels[which(region == 42)] # Adjust bellary.neighbor
    npixels.sum[which(region == 45)] <- npixels[which(region == 45)] + npixels[which(region == 47)] # Adjust tamilnadu
    npixels.sum[which(region == 21)] <- npixels[which(region == 21)] + npixels[which(region == 23)] # Adjust assam 
    
    idx.shp <- which(SHPNames == '7up.dist.assam')
    idx.point <- which(df.country$Region == 21) # point in assam
    region.shp <- readOGR(paste0(SHPPath_India, SHPNames[idx.shp], '.shp'))
    region.shp <- spTransform(region.shp, mycrs) 
    point.in <- over(point[idx.point], region.shp)
    point.in <- sum(!is.na(point.in$FOI_val))
    npixels.sum[which(region == 15)] <- npixels[which(region == 15)] + npixels[which(region == 23)] + point.in # Adjust 7up.dist.assam
    
    # Adjust FOI for overlaped sub regions
    
    FOI.total <- FOI.old * npixels.sum
    FOI.new[which(region == 41)] <- (FOI.total[which(region == 41)] - FOI.total[which(region == 42)]) / npixels[which(region == 41)] # Adjust bellary.neighbor
    FOI.new[which(region == 45)] <- (FOI.total[which(region == 45)] - FOI.total[which(region == 47)]) / npixels[which(region == 45)] # Adjust tamilnadu
    FOI.new[which(region == 25)] <- (FOI.total[which(region == 25)] - FOI.total[which(region == 26)] - FOI.total[which(region == 28)]) / npixels[which(region == 25)] # Adjust gorakhpur.div
    FOI.new[which(region == 19)] <- (FOI.total[which(region == 19)] - FOI.total[which(region == 28)]) / npixels[which(region == 19)] # Adjust N.uttar
    FOI.new[which(region == 13)] <- (FOI.total[which(region == 13)] - FOI.total[which(region == 28)] - FOI.total[which(region == 26)] - 
                                       FOI.new[which(region == 19)] * npixels[which(region == 19)] - 
                                       FOI.new[which(region == 25)] * npixels[which(region == 25)]) / npixels[which(region == 13)] # Adjust uttar
    FOI.new[which(region == 21)] <- (FOI.total[which(region == 21)] - FOI.total[which(region == 23)]) / npixels[which(region == 21)] # Adjust assam
    FOI.new[which(region == 15)] <- (FOI.total[which(region == 15)] - FOI.total[which(region == 23)] - 
                                       point.in * FOI.new[which(region == 21)]) / npixels[which(region == 15)] # Adjust 7up.dist.assam (Assume that every cells in assam is evenly distributed)
    
  }
  
  # ===== Update to Dataframe =====
  idx <- which(FOI.new != FOI.old)
  region.update <- region[idx]
  FOI.update <- FOI.new[idx]
  for(i in 1 : length(region.update)){
    idx <- which(df.origin$Region == region.update[i])
    df.origin$FOI[idx] <- FOI.update[i]
  }
  rm(df.country)
}

saveRDS(df.origin, paste0('Generate/Overlay_DF/', 'Adjusted_Overlay_Study.Rds'))

cat('===== FINISH [Adjust_Overlay.R] =====\n')

## --- CREATE ADJUSTED FOI MAP RASTER TO VISUALIZE --- ##

# create_raster_from_df <- function(dataframe, res = c(5, 5),
#                                   crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs",
#                                   name = 'rasterdf', savefile = FALSE){
#     crs <- crs(crs)
#     rasterdf <- rasterFromXYZ(dataframe, res = res, crs = crs)
#     if (savefile){
#         writeRaster(rasterdf, name, overwrite = TRUE, format = "GTiff")
#     }
#     return(rasterdf)
# }
# 
# temp <- create_raster_from_df(df.origin[ , c(1, 2, 30)], name = 'AllDF_Adjusted_WP_Imputed_Land', savefile = TRUE)
