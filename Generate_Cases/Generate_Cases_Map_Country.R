# NOTE #
# Generate Map (SHP) files for each country (total cases in a country) from dataframe (From Generate_Cases_Dataframe.R)
# Compare to VIMC Result (Modelling way)
# ---- #

library(sp)
library(raster)
library(rgdal)

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!!
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)
# Create folder to store the generated SHP result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/Cases_SHP/'), showWarnings = TRUE)


##### CREATE SHP FILE #####
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
crs_new <- crs("+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs")

# Read data regions DF
df.regions <- readRDS('Generate/Coord_Regions_Final.Rds')

# Read SHP File of endemic area
region.shp <- readOGR('Data/Shapefile_Endemic/Ende_map_feed.shp')
countries <- region.shp@data$Country
countries <- as.character(countries) # countries in endemic areas

# Read data
LinkData <- 'Generate/Cases/'
ListFiles <- list.files(LinkData)
idx_file <- length(ListFiles) # Total cases of all age group
df <- readRDS(paste0(LinkData, ListFiles[idx_file]))

region.shp@data$Cases <- 0
# Find Cases for each country
for (idx_country in 1 : length(countries)){
    country <- countries[idx_country]
    if (country != 'MAC'){
        idx_row_regions <- which(df.regions$regions == idx_country)
        total_cases <- sum(df$Total[idx_row_regions])
        region.shp@data$Cases[idx_country] <- total_cases    
    }
}

writeOGR(region.shp, ".", "Generate/Cases_SHP/Total_Cases_SHP", driver="ESRI Shapefile")

##### COMPARE WITH VIMC: Comparing with the result of VIMC templates we ran last year #####
# vimc <- read.csv("~/DuyNguyen/RProjects/Rstan_Quan/Template_Generate/2017gavi6/MeanCases/naive_2017gavi6.csv")
# vimc.2015 <- vimc[which(vimc$year == 2015), ]
# rm(vimc)
# vimc.2015 <- vimc.2015[, c(3, 4, 8)] # Age, Country, Cases
# vimc.2015$country <- as.character(vimc.2015$country)
# 
# countries <- unique(vimc.2015$country)
# vimc.cases <- data.frame(country = countries, cases = 0)
# vimc.cases$country <- as.character(vimc.cases$country)
# 
# for (idx.country in 1 : length(countries)){
#     country <- countries[idx.country]
#     cases <- sum(vimc.2015$cases[which(vimc.2015$country == country)])
#     vimc.cases$cases[idx.country] <- cases
# }
# 
# rf <- readOGR('~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Cases_Country_SHP/Cases_SHP.shp')
# rfdata <- rf@data
# rm(rf)
# rfdata <- rfdata[, c(1, 4)] # Country, Cases
# rfdata$Country <- as.character(rfdata$Country)
# # Fix problem Low.NPL + High.NPL
# idx_low <- which(rfdata$Country == 'Low.NPL')
# idx_high <- which(rfdata$Country == 'High.NPL')
# rfdata$Cases[idx_low] <- rfdata$Cases[idx_low] + rfdata$Cases[idx_high]
# rfdata$Country[idx_low] <- 'NPL'
# rfdata <- rfdata[-idx_high, ]
# 
# # Compare 2 data #
# compare <- data.frame(country = countries, vimc = vimc.cases$cases, rf = 0)
# for (idx.country in 1 : length(countries)){
#     country <- countries[idx.country]
#     idx <- which(rfdata$Country == country)
#     compare$rf[idx.country] <- rfdata$Cases[idx]
# }
