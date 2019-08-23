### NOTE ###
# Adjust Population Dataframe (Map) to match with Quan (orginal also from UN but adjusted for some subnation regions in RUS, PAK, AUS) and UN data
# CHN = CHN + MAC (as mapping MAC, idx = 14, is inside CHN)
# ratio = alternative / Duy --> adjusted pop = Duy * ratio
### ---- ###

cat('===== START [Adjust_Pop_To_Match_UN.R] =====\n')

# Get directory of the script (this part only work if source the code, wont work if run directly in the console)
# This can be set manually !!!
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

##### Create dataframe of population from UN Excel ####
# Read Country index data #
Country_Index <- readRDS("Generate/Country_Index.Rds") # index of countries
Coord_Regions_Final <- readRDS("Generate/Coord_Regions_Final.Rds") # index of pixel

# Combine Low.NPL and High.NPL into 1 NPL
pop.UN <- data.frame(Country = Country_Index, Pop = 0)
pop.UN$Country <- as.character(pop.UN$Country)
pop.UN <- pop.UN[-which(pop.UN$Country == 'Low.NPL'),]
pop.UN$Country[which(pop.UN$Country == 'High.NPL')] <- 'NPL'

# Add infor from UN Excel
pop.UN$Pop[which(pop.UN$Country == 'AUS')] <- 23799556
pop.UN$Pop[which(pop.UN$Country == 'BGD')] <- 161200886
pop.UN$Pop[which(pop.UN$Country == 'BRN')] <- 417542
pop.UN$Pop[which(pop.UN$Country == 'BTN')] <- 787386
pop.UN$Pop[which(pop.UN$Country == 'CHN')] <- 1397028553 # + 600942 # China + Macau
pop.UN$Pop[which(pop.UN$Country == 'HKG')] <- 7245701
pop.UN$Pop[which(pop.UN$Country == 'IDN')] <- 258162113
pop.UN$Pop[which(pop.UN$Country == 'IND')] <- 1309053980
pop.UN$Pop[which(pop.UN$Country == 'JPN')] <- 127974958
pop.UN$Pop[which(pop.UN$Country == 'KHM')] <- 15517635
pop.UN$Pop[which(pop.UN$Country == 'KOR')] <- 50593662
pop.UN$Pop[which(pop.UN$Country == 'LAO')] <- 6663967
pop.UN$Pop[which(pop.UN$Country == 'LKA')] <- 20714040
pop.UN$Pop[which(pop.UN$Country == 'MAC')] <- 600942
pop.UN$Pop[which(pop.UN$Country == 'MMR')] <- 52403669
pop.UN$Pop[which(pop.UN$Country == 'MYS')] <- 30723155
pop.UN$Pop[which(pop.UN$Country == 'NPL')] <- 28656282
pop.UN$Pop[which(pop.UN$Country == 'PAK')] <- 189380513
pop.UN$Pop[which(pop.UN$Country == 'PHL')] <- 101716359
pop.UN$Pop[which(pop.UN$Country == 'PNG')] <- 7919825
pop.UN$Pop[which(pop.UN$Country == 'PRK')] <- 25243917
pop.UN$Pop[which(pop.UN$Country == 'RUS')] <- 143888004
pop.UN$Pop[which(pop.UN$Country == 'SGP')] <- 5535262
pop.UN$Pop[which(pop.UN$Country == 'THA')] <- 68657600
pop.UN$Pop[which(pop.UN$Country == 'TLS')] <- 1240977
pop.UN$Pop[which(pop.UN$Country == 'TWN')] <- 23485755
pop.UN$Pop[which(pop.UN$Country == 'VNM')] <- 93571567

idx_MAC <- which(pop.UN$Country == 'MAC')
idx_CHN <- which(pop.UN$Country == 'CHN')
pop.UN$Pop[idx_CHN] <- pop.UN$Pop[idx_CHN] + pop.UN$Pop[idx_MAC]
pop.UN <- pop.UN[-idx_MAC, ]


##### Read pop from Quan Data (also from UN, but adjust to match subnational regions) ####
# pop_data1 <- readRDS("JE_model_Quan/data/population/Naive_pop_24ende_1950_2015.rds")
pop_data1 <- readRDS("Data/Naive_pop_24ende_1950_2015.rds") # Population by age at each region
pop_data1 <- pop_data1[ ,c(1, which(colnames(pop_data1) == 'X2015'))]
pop_data1$region <- as.character(pop_data1$region)
# foi_data1 <- readRDS("JE_model_Quan/results/areas_lambda/ende_24_regions_lambda_extr_or.rds")
foi_data1 <- readRDS("Data/ende_24_regions_lambda_extr_or.rds") # FOI result from catalytic models at each region
select_region <- c(1:6, 11:15, 19:24, 28:30, 32:40, 48) # regions that we considered in endemic areas (WHO-IG)
select_region <- as.character(foi_data1$region[select_region])
pop_data1 <- pop_data1[which(pop_data1$region %in% select_region),]

countries_data1 <- unique(pop_data1$region)
pop.Q <- data.frame(country = countries_data1, totalpop = 0)
pop.Q$country <- as.character(pop.Q$country)
for (idx.country in 1 : length(countries_data1)){
    country <- countries_data1[idx.country]
    pop <- sum(pop_data1$X2015[which(pop_data1$region == country)])
    pop.Q$totalpop[idx.country] <- pop
}

# adjust IDN.Low, IDN.High
idx.low <- which(pop.Q$country == 'Low.IDN')
idx.high <- which(pop.Q$country == 'High.IDN')
pop.Q$totalpop[idx.low] <- sum(pop.Q$totalpop[c(idx.low, idx.high)])
pop.Q$country[idx.low] <- 'IDN'
pop.Q <- pop.Q[-idx.high, ]

# adjust IND.Low, IND.Medium, IND.High
idx.low <- which(pop.Q$country == 'Low.IND')
idx.medium <- which(pop.Q$country == 'Medium.IND')
idx.high <- which(pop.Q$country == 'High.IND')
pop.Q$totalpop[idx.low] <- sum(pop.Q$totalpop[c(idx.low, idx.medium, idx.high)])
pop.Q$country[idx.low] <- 'IND'
pop.Q <- pop.Q[-c(idx.high, idx.medium), ]
countries_data1 <- unique(pop.Q$country)

# adjust Low.NPL and High.NPL
idx_low <- which(pop.Q$country == 'Low.NPL')
idx_high <- which(pop.Q$country == 'High.NPL')
pop.Q$totalpop[idx_low] <- pop.Q$totalpop[idx_low] + pop.Q$totalpop[idx_high]
pop.Q$country[idx_low] <- 'NPL'
pop.Q <- pop.Q[-idx_high, ]

# adjust Low.CHN and High.CHN
idx_low <- which(pop.Q$country == 'Low.CHN')
idx_high <- which(pop.Q$country == 'High.CHN')
pop.Q$totalpop[idx_low] <- pop.Q$totalpop[idx_low] + pop.Q$totalpop[idx_high]
pop.Q$country[idx_low] <- 'CHN'
pop.Q <- pop.Q[-idx_high, ]

# adjust name of total_TWN
pop.Q$country[24] <- 'TWN'

colnames(pop.Q) <- c('Country', 'Pop')

rm(foi_data1, pop_data1)

##### Read Pop from the Duy dataframe (imputed in the randomforest dataset) #####
Endemic_DF_WP_Imputed_Land <- readRDS("Data/Endemic_DF_WP_Full_Cov_Imputed_Land.Rds") # dataframe containing all imputed features (no missing values here)
idx_col_pop <- which(colnames(Endemic_DF_WP_Imputed_Land) == 'Pop_Count_WP_SEDAC_2015')
df.pop <- Endemic_DF_WP_Imputed_Land[, c(1, 2, idx_col_pop)]
rm(Endemic_DF_WP_Imputed_Land)

# Create Entire Pop WP_SEDAC for each country #
pop.D <- data.frame(country = Country_Index, totalpop = 0)
pop.D$country <- as.character(pop.D$country)
for (idx.country in 1 : length(Country_Index)){
    idx_point <- which(Coord_Regions_Final$regions == idx.country)
    if (length(idx_point) > 0){
        pop <- sum(df.pop$Pop_Count_WP_SEDAC_2015[idx_point])
        pop.D$totalpop[idx.country] <- pop
    }
}
# Fix problem Low.NPL + High.NPL
idx_low <- which(pop.D$country == 'Low.NPL')
idx_high <- which(pop.D$country == 'High.NPL')
pop.D$totalpop[idx_low] <- pop.D$totalpop[idx_low] + pop.D$totalpop[idx_high]
pop.D$country[idx_low] <- 'NPL'
pop.D <- pop.D[-idx_high, ]

# Remove MAC --> CHN = CHN + MAC (Pop MAC in the map is 0 since in the map MAC belong to CHN --> no pixel belongs to MAC)
pop.D <- pop.D[-which(pop.D$country == 'MAC'), ]

# Still keep HKG apart from CHN --> dont run the 4 following lines 
# idx_HKG <- which(pop.D$country == 'HKG')
# idx_CHN <- which(pop.D$country == 'CHN')
# pop.D$totalpop[idx_CHN] <- pop.D$totalpop[idx_CHN] + pop.D$totalpop[idx_HKG]
# pop.D <- pop.D[-idx_HKG, ]

colnames(pop.D) <- c('Country', 'Pop')

##### Find CONVERT RATIO #####
# ratio = alternative / Duy --> adjusted pop = Duy * ratio
Country_All <- unique(pop.UN$Country)
Country_Part <- c('AUS', 'RUS', 'PAK') # countries that endemics are subnational regions (not entire country) --> use subregion pop data (Quan Result)
Country_Entire <- setdiff(Country_All, Country_Part) # Countries that endemics are entire countries --> use UN data

pop.ratio <- data.frame(Country = Country_All, Dataset = 'A', Ratio = 0)
pop.ratio$Country <- as.character(pop.ratio$Country)
pop.ratio$Dataset <- as.character(pop.ratio$Dataset)

for (idx in 1 : length(Country_Index)){
    country <- Country_Index[idx]
    cat('[Ratio] Processing:', country, '\n')
    if (country != 'MAC'){
        if (country == 'Low.NPL' || country == 'High.NPL'){
            country <- 'NPL'
        }
        idx_ratio <- which(pop.ratio$Country == country)
        idx_D <- which(pop.D$Country == country)
        if (country %in% Country_Part){ # Use Quan Data
            idx_alter <- which(pop.Q$Country == country)
            pop.ratio$Dataset[idx_ratio] <- 'Q'
            ratio <- pop.Q$Pop[idx_alter] / pop.D$Pop[idx_D]
        }else{ # Use UN data
            idx_alter <- which(pop.UN$Country == country)
            pop.ratio$Dataset[idx_ratio] <- 'UN'
            ratio <- pop.UN$Pop[idx_alter] / pop.D$Pop[idx_D]
        }
        pop.ratio$Ratio[idx_ratio] <- ratio
    }
}

##### Adjust Pop #####
for (i in 1 : length(Country_Index)){
    country <- Country_Index[i]
    cat('[Adjusting] Processing:', country, '\n')
    if (country != 'MAC'){
        if (country == 'Low.NPL' || country == 'High.NPL'){
            country <- 'NPL'
        }
        idx_Coord <- which(Coord_Regions_Final$regions == i)
        idx_ratio <- which(pop.ratio$Country == country)
        df.pop$Pop_Count_WP_SEDAC_2015[idx_Coord] <- df.pop$Pop_Count_WP_SEDAC_2015[idx_Coord] * pop.ratio$Ratio[idx_ratio]
    }
}
##### SAVE #####
saveRDS(df.pop, 'Generate/Adjusted_Pop_Map.Rds')

cat('===== FINISH [Adjust_Pop_To_Match_UN.R] =====\n')