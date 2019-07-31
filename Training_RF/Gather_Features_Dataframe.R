# --- NOTE ---
# This script is used to gather all calibrated TIF files into 1 dataframe.
# This dataframe will be used for the Random Forest Model later
# The calibrated TIF files need to be well-organized in a folder (applicable with subfolders)
# The last part is used to rename the column names in the dataframe (since the original is messy)
# SINCE I HAVE RUN THE CODE FOR YOU --> IF YOU WANT TO EXTRACT LAND-PIXEL --> RUN THE EXTRACT LAND PIXEL part
# ---------- #

library(sp)
library(raster)
library(rgdal)
library(prodlim)

cat('===== START [Gather_Features_Dataframe.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Gather_DF/'), showWarnings = TRUE)

## =================== CREATE RDS FILE (NOT ADJUSTED COLNAMES) ===================
Match_Feature <- function(ref.df, ft.df){
  # Matching coordinate points in feature dataframe ft.df with points in reference dataframe ref.df (having same coordinates)
  # if ft.df does not have points in ref.df --> these points in ft.df are NA
  # Points in ref.df and ft.df have to be same in CRS, resolution, extents --> make sure they match to each other
  # Both dataframes have 3 columns naming values, x, y
  # Input
  #   ref.df: reference dataframe containing coordinates that will be used to to match with ft.df (should be bioclimatic feature as they dont have any missing values --> full of coordinates)
  #   ft.df: feature dataframe want to match the values to the corresponding coordinates in ref.df
  # Output
  #   A dataframe containing coordinate points from ref.df, values from ft.df (or NA if missing)
  
  match_pos <- row.match(ref.df[c('x', 'y')], ft.df[c('x', 'y')]) # same coordinates --> return index in ft.df, else --> NA
  
  ntotal <- nrow(ref.df) # total points in ref.df
  ninvalid <- sum(is.na(match_pos)) # number of points appearing in ref.df but absent in ft.df 
  nvalid <- ntotal - ninvalid # number of points both dataframes have
  cat("Valid Pixels:", nvalid, "/", ntotal, "-----", round(nvalid/ntotal*100, 2), "%\n")
  cat("NA Pixels:", ninvalid, "/", ntotal, "-----", round(ninvalid/ntotal*100, 2), "%\n")
  
  Match <- data.frame(value = numeric(), x = numeric(), y = numeric()) # empty dataframe
  Match <- rbind(Match, ft.df[match_pos[!is.na(match_pos)], ]) # assign valid points in ft.df to Match
  
  if (ninvalid > 0){
    na_pos <- which(is.na(match_pos)) # find index of na points (these index are index in ref.df)
    na.df <- ref.df[c('x', 'y')][na_pos,] # take coordinates of in ref.df but not in ft.df
    na.df$value <- NA # assign NA
    na.df <- na.df[c('value', 'x', 'y')] # reorder columns to match value - x - y
    colnames(na.df) <- c(colnames(Match)[1], 'x', 'y')
    Match <- rbind(Match, na.df) # Binding Valid - Invalid points
  }
  
  Match <- Match[order(-Match$y, Match$x), ] # reorder rows
  return(Match)
}

WholeData <- "Generate/Calibrated/"
folders <- list.dirs(path = WholeData, full.names = FALSE, recursive = FALSE) # list all names of folders in the WholeData Link
flag <- 0 # checked if any specific map is chosen or not
for (idx.folders in 1:length(folders)){
  subfolders <- folders[idx.folders]
  cat("=============== Folder:", subfolders, '(', idx.folders, '/', length(folders), ") ===============\n")
  LinkData <- paste0(WholeData, subfolders, '/')
  files_list <- list.files(path = LinkData)
  for (idx.files in 1:length(files_list)){
    file <- files_list[idx.files]
    cat("##### TIF:", file, '(', idx.files, '/', length(files_list), ") #####\n")
    map <- raster(paste0(LinkData, file))
    map.spdf <- as(map, "SpatialPixelsDataFrame")
    rm(map)
    map.df <- as.data.frame(map.spdf)
    rm(map.spdf)
    if (flag == 0){ # take the specific map to be the axes
      Endemic.df <- map.df[, c(2, 3, 1)]
      rm(map.df)
      Endemic.df <- Endemic.df[order(-Endemic.df$y, Endemic.df$x), ]
      flag <-  1
    }else{
      Match <- Match_Feature(Endemic.df, map.df)
      rm(map.df)
      Endemic.df <- cbind(Endemic.df, Match[, 1])
      colnames(Endemic.df)[ncol(Endemic.df)] <- colnames(Match)[1]
      rm(Match)
    }
    saveRDS(Endemic.df, file = paste0("Generate/Gather_DF/Original_Features_Endemic.Rds"))
  }
}

## =================== EXTRACT LAND PIXEL ===================
## You can save the Land-pixel only --> pixel that have Water value (from the Water classification map) = 0 is land
# Endemic.df <- readRDS('Generate/Dataframe/Original_Features_Endemic.Rds')
# Endemic.df.land <- Endemic.df[which(Endemic.df$WM == 0), ] # remember to change to column name. Here WM is the column for Water-Land classification
# saveRDS(Endemic.df.land, file = paste0("Generate/Dataframe/Original_Features_Endemic_Land.Rds"))

# Studies.df <- Endemic.df[!is.na(Endemic.df$FOI), ] # Take pixels that have FOI values from catalytic models --> Use this dataframe to train and evaluate the RF model
# Studies.df.land <- Studies.df[which(Studies.df$WM == 0), ] # Take the land pixels
# saveRDS(Studies.df, file = paste0("Generate/Dataframe/Original_Features_Studies.Rds"))
# saveRDS(Studies.df.land, file = paste0("Generate/Dataframe/Original_Features_Studies_Land.Rds"))

## ================ ADJUST COLNAMES =================
## Need to run this part (but have to change manually based on your context)
# rm(list =ls())
# 
# Endemic.df <- readRDS('Endemic_DF.Rds')
# 
# name.old <- colnames(Endemic.df)
# 
# name.Bio <- c('Bio_01', 'Bio_02', 'Bio_03', 'Bio_04', 'Bio_05', 'Bio_06', 'Bio_07', 'Bio_08', 'Bio_09', 'Bio_10',
#               'Bio_11', 'Bio_12', 'Bio_13', 'Bio_14', 'Bio_15', 'Bio_16', 'Bio_17', 'Bio_18', 'Bio_19')
# 
# name.Demo <- c()
# a = 0
# b = 4
# while (a <= 85){
#   if (a < 10){
#     t0 <- paste0('demo_0', a)    
#   }else{
#     if (a <= 80){
#       t0 <- paste0('demo_', a)    
#     }else{
#       t0 <- paste0('demo_85plus')
#     }
#   }
#   if (b < 10){
#     t0 <- paste0(t0, '_0', b)    
#   }else{
#     if (a <= 80){
#       t0 <- paste0(t0, '_', b)
#     }
#   }
#   t1 <- paste0(t0, '_b_2010_cntm')
#   t2 <- paste0(t0, '_b_2010_dens')
#   t3 <- paste0(t0, '_f_2010_cntm')
#   t4 <- paste0(t0, '_f_2010_dens')
#   t5 <- paste0(t0, '_m_2010_cntm')
#   t6 <- paste0(t0, '_m_2010_dens')
#   
#   name.Demo <- c(name.Demo, t1, t2, t3, t4, t5, t6)
#   
#   a <- a + 5
#   b <- b + 5
# }
# 
# t0 <- 'demo_00_14'
# t1 <- paste0(t0, '_b_2010_cntm')
# t2 <- paste0(t0, '_b_2010_dens')
# t3 <- paste0(t0, '_f_2010_cntm')
# t4 <- paste0(t0, '_f_2010_dens')
# t5 <- paste0(t0, '_m_2010_cntm')
# t6 <- paste0(t0, '_m_2010_dens')
# name.Demo <- c(name.Demo, t1, t2, t3, t4, t5, t6)
# 
# name.Pop <- c('Pop_2000', 'Pop_2005', 'Pop_2010', 'Pop_2015', 'Pop_2020')
# 
# name.new <- c('x', 'y', name.Bio, name.Demo, 'Elv', 'FOI', 'Pigs', name.Pop, 'Rice', 'UR', 'VM', 'WM') 
# 
# colnames(Endemic.df) <- name.new
# 
# saveRDS(Endemic.df, file = "Endemic_DF_Rename.Rds")
# 
# rm(list = ls())

cat('===== FINISH [Gather_Features_Dataframe.R] =====\n')
