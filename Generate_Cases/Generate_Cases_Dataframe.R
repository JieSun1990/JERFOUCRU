# NOTE #
# Basically same with Generate_Cases_DF.R --> but here use both original VIMC data and Quan (VIMC+UN) data
# Create Cases per pixel map based on FOI map and Population VIMC file
# Use catalytic model to find cases: Cases = [1 - exp(-lambda)] * exp(-lambda * age) * symtomatic_rate * pop_age
# lambda: FOI from map
# age: age of the group want to find cases (0, 1, 2, ..., 99)
# symtomatic_rate: rate from sampling 
# pop_age: population at the specific age --> find by using VIMC pop file --> age distribution --> pop per pixel map
# Setting from Create_Cases_Deaths_v2_2.R to generate case with Quan (seed = 114) --> this is used to generate cases for VIMC last year
# PSym <- runif(1600, 1/500, 1/250)
# PMor <- runif(1600, 0.1, 0.3) 
# PDis <- runif(1600, 0.3, 0.5)
# However, Quan did stored his parameters for these values -->  we can used this to compared with Quan
# ---- #

library(sp)
library(raster)
library(rgdal)
library(rgeos)

####### Generate Cases Pixel DF #######
# Read FOI Map file
Folder.CSV <- '/home/duynguyen/DuyNguyen/PythonProjects/OUCRU_JE/Result with Coor/EM/RescaleTVT_Once/Land/'
df.csv <- read.csv(paste0(Folder.CSV, 'Endemic_result_Full_Cov_TVT_Land_400.csv'), sep = '\t')
df.csv <- df.csv[, -1]
df.foi <- df.csv[, c(1, 2, 3)]
rm(df.csv)

##### Read Pop Map Data (Dataframe training) #####
df.pop <- readRDS('~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Adjusted_Pop_Map.Rds')
colnames(df.pop) <- c('x', 'y', 'Pop')

##### Read Population data collected by Quan (UN and subnational regions in PAK, AUS, RUS) #####
# This file is the result after running Extract_Age_Distribution_Population.R
vimc.pop <- readRDS('~/DuyNguyen/RProjects/OUCRU JE/Compare Values/Naive_pop_24ende_1950_2015_Country.Rds')

##### Set up symptomatic rate #####
# set.seed(114) # make sure the sampling is the same all the time we run the file
# PSym <- runif(1600, 1/500, 1/250)
# PSym_mean <- mean(PSym) # take means

# take same value with Quan in order to make it easy for comparing
PSym <- readRDS('~/DuyNguyen/JE_model_Quan/data/uncertainty_quantities/symp_rate_dist.rds')
PSym_mean <- mean(PSym)

##### Find age distribution of each country supported by VIMC #####
vimc.pop$distribution <- 0
countries <- unique(vimc.pop$country_code) # countries which are supported by VIMC
for (country in countries){
    idx_row <- which(vimc.pop$country_code == country)
    pop_sum <- sum(vimc.pop$X2015[idx_row])
    pop_distribute <- vimc.pop$X2015[idx_row] / pop_sum
    vimc.pop$distribution[idx_row] <- pop_distribute
}

##### Read assigned regions dataframe #####
# Note that MACAU is 14 but there is no pixel is assigned as 14 since MACAU belongs to China (index 5)
df.regions <- readRDS('~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Coord_Regions_Final.Rds') 
Country_Idx <- readRDS('~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Country_Index.Rds')

###### Create empty dataframe for age pop distribution (nrow = npixel, ncol = 100 agegroup + 2 coord) #####
headers <- c('x', 'y', paste0('Age_0', c(0:9)), paste0('Age_', c(10:99)))
df.popage <- as.data.frame(matrix(0, ncol = 102, nrow = nrow(df.foi)))
colnames(df.popage) <- headers
df.popage$x <- df.foi$x
df.popage$y <- df.foi$y

for (i in 1 : length(Country_Idx)){
    country <- Country_Idx[i]
    cat('Processing', country, '\n')
    if (country != 'MAC'){ # Do not run for MAC
        idx_region <- which(df.regions$regions == i)
        if (country == 'Low.NPL' || country == 'High.NPL'){
            country <- 'NPL'
        }
        if (country == 'HKG'){ # Used age distribution of CHN and apply to HKG
            country <- 'CHN'
        }
        idx_vimc_pop <- which(vimc.pop$country_code == country)
        if (length(idx_vimc_pop) == 0){ # DO NOT HAVE VIMC POP DATA FOR THIS COUNTRY
            for (idx_col in 3 : ncol(df.popage)){
                df.popage[[idx_col]][idx_region] <- df.pop$Pop[idx_region] / 100 # equally portion for all 100 age groups
            }
        }else{ # HAVE VIMC POP DATA
            for (idx_col in 3 : ncol(df.popage)){
                df.popage[[idx_col]][idx_region] <- df.pop$Pop[idx_region] * vimc.pop$distribution[idx_vimc_pop[idx_col - 2]]
            }
        }
    }
}

###### Find Cases for each pixels for each age group #####
rm(df.pop, df.regions, vimc.pop)
headers <- c('x', 'y', paste0('Age_0', c(0:9)), paste0('Age_', c(10:99)))
df.casesage <- as.data.frame(matrix(0, ncol = 102, nrow = nrow(df.foi)))
colnames(df.casesage) <- headers
df.casesage$x <- df.foi$x
df.casesage$y <- df.foi$y
for (i in 3 :  ncol(df.popage)){
    df.casesage[[i]] <- (1 - exp(-1 * df.foi$Predict)) * exp(-1 * df.foi$Predict * (i - 3)) * PSym_mean * df.popage[[i]]
}
df.casesage$Total <- rowSums(df.casesage[,3:102])
# saveRDS(df.casesage, 'Cases_DF_Agegroup.Rds') # intensive file, large size --> dont recommend to save this file

for (i in 3 : ncol(df.casesage)){
    cat('Saving', colnames(df.casesage)[i], '\n')
    df <- df.casesage[ ,c(1, 2, i)]
    saveRDS(df, paste0('Cases_', colnames(df.casesage)[i], '.Rds'))
}
