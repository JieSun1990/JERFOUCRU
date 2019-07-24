# NOTE #
# Extract and compare cases between RF and MOdelling
# ---- #

library(ggplot2)
library(tidyr)

Extract_Values_Country <- function(DF_Vals, DF_Coords, Index){
    # Extract values of entire map based on their countries
    # DF_Vals: Dataframe containing values in entire map
    # DF_Coords: Dataframe containing pixel's index indicating which country it belongs to
    # Index: Name of index in DF_Coords
    # Index + DF_Coords has to match
    # Coords in DF_Vals + DF_Coords have to match
    
    result <- vector('list', length(Index))
    names(result) <- Index
    # Check Coord match
    dx <- abs(DF_Vals$x - DF_Coords$x)
    dy <- abs(DF_Vals$y - DF_Coords$y)
    if (dx == 0 && dy == 0){
        for (idx.country in 1 : length(Index)){
            idx_point <- which(DF_Coords[[3]] == idx.country)
            if (length(idx_point) > 0){
                vals <- DF_Vals[[3]][idx_point]
                result[[idx.country]] <- vals
            }
        }
    }else{
        cat('COORDINATES DO NOT MATCH --> STOP!!!\n')
    }
    return(result)
}

# Read data
LinkData <- '~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Data_Cases/'
ListFiles <- list.files(LinkData)

##### Read Map data #####
Country_Index <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Country_Index.Rds") # index of countries
Coord_Regions_Final <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Coord_Regions_Final.Rds") # country index of each pixel
Cases.map <- readRDS(paste0(LinkData, ListFiles[101])) # Take total cases (index 101)

Cases.map <- Extract_Values_Country(Cases.map, Coord_Regions_Final, Country_Index)
# Fix Low.NPL and High.NPL
Cases.map$NPL <- c(Cases.map$Low.NPL, Cases.map$High.NPL)
Cases.map$MAC <- NULL
Cases.map$Low.NPL <- NULL
Cases.map$High.NPL <- NULL
# Add HKG in CHN
Cases.map$CHN <- c(Cases.map$CHN, Cases.map$HKG)
Cases.map$HKG <- NULL

# Sum cases in all pixels
for (idx in 1 : length(Cases.map)){
    Cases.map[[idx]] <- sum(Cases.map[[idx]])
}

##### Read Modelling data #####
Cases.mod <- readRDS("~/DuyNguyen/JE_model_Quan/results/cases_gen/no_vac_cases_gen_age_sum_or.rds") # year 1950 - 2015 --> 66 cols / 1600 rows --> 1600 FOI posteriors
for (i in 1 : length(Cases.mod)){
    Cases.mod[[i]] <- as.numeric(Cases.mod[[i]][,66])
}

# Cases.mod <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Compare Values/no_vac_cases_gen_age_sum_or_Adjust.Rds") # year 2015 (Adjust pop to match with SEDAC) --> 1600 values for 1600 FOI posteriors


# Adjust Low.CHN, High.CHN
Cases.mod$CHN <- Cases.mod$Low.CHN + Cases.mod$High.CHN
Cases.mod$Low.CHN <- NULL
Cases.mod$High.CHN <- NULL
# Adjust Low.IDN, High.IDN
Cases.mod$IDN <- Cases.mod$Low.IDN + Cases.mod$High.IDN
Cases.mod$Low.IDN <- NULL
Cases.mod$High.IDN <- NULL
# Adjust Low.IND, High.IND, Medium.IND
Cases.mod$IND <- Cases.mod$Low.IND + Cases.mod$Medium.IND + Cases.mod$High.IND
Cases.mod$Low.IND <- NULL
Cases.mod$High.IND <- NULL
Cases.mod$Medium.IND <- NULL
# Adjust Low.NPL, High.NPL
Cases.mod$NPL <- Cases.mod$Low.NPL + Cases.mod$High.NPL
Cases.mod$Low.NPL <- NULL
Cases.mod$High.NPL <- NULL
# Adjust total_TWN
names(Cases.mod)[which(names(Cases.mod) == 'total_TWN')] <- 'TWN'

# Mean cases in all elements (1600 FOIs --> 1600 results --> take means)
for (idx in 1 : length(Cases.mod)){
    Cases.mod[[idx]] <- mean(Cases.mod[[idx]])
}

##### Create DF Compare #####
Countries <- names(Cases.map)
df <- data.frame(country = Countries, mod = 0, map = 0)
df$country <- as.character(df$country)
for (idx in 1 : nrow(df)){
    country <- df$country[idx]
    df$map[idx] <- Cases.map[[which(names(Cases.map) == country)]]
    df$mod[idx] <- Cases.mod[[which(names(Cases.mod) == country)]]
}
df$map <- round(df$map)
df$mod <- round(df$mod)

# level_oiginal <- AUS BRN BTN RUS SGP TLS JPN LAO PRK PNG TWN LKA KHM PAK KOR MYS NPL THA MMR VNM PHL BGD IDN IND CHN
# lv <- c('AUS', 'BRN', 'BTN', 'TLS', 'RUS', 'SGP', 'LAO', 'PNG', 'KHM',
#         'LKA', 'PRK', 'TWN', 'NPL', 'MYS', 'PAK', 'KOR', 'MMR', 'THA', 'VNM',
#         'PHL', 'JPN', 'BGD', 'IDN', 'IND', 'CHN')
df$country <- factor(df$country, levels = unique(df$country[order(df$mod)]), ordered = TRUE) # order based on mod values
# df$country <- factor(df$country, levels = lv, ordered = TRUE) # order based on mod values

df_long <- gather(df, method, cases, mod, map, factor_key = TRUE)
colnames(df_long) <- c('Country', 'Method', 'Cases')
df_long$Method <- as.character(df_long$Method)
df_long$Method[which(df_long$Method == 'mod')] <- 'WHO-IG'
df_long$Method[which(df_long$Method == 'map')] <- 'Mapping'
##### PLOT #####
## function helping to remove part of y axis
# trans <- function(x, fr = 25) {
#     c(x[x <= fr], fr + (0.05 * x[x > fr]))
# }
# yticks <- c(0, 10, 100, 500, 1000, 2500, 5000, 10000, 15000, 40000, 60000)
# df_long$cases_new <- 0
# for (i in 1 : nrow(df_long)){
#     df_long$cases_new[i] <- trans(df_long$cases[i], 500)
# }
# p <- ggplot(df_long, aes(x = country, y = cases_new, fill = method)) + geom_bar(stat = 'identity', position = position_dodge())
# p <- p + geom_rect(aes(xmin = 0, xmax = 26, ymin = 500, ymax = 510), fill = 'white')
# p <- p + scale_y_continuous(limits = c(0, NA), breaks = trans(yticks, 500), labels = yticks)
# p <- p + theme(axis.text.x = element_text(angle = 90))


p <- ggplot(df_long, aes(x = Country, y = Cases, fill = Method)) + geom_bar(stat = 'identity', position = position_dodge())
p <- p + theme(axis.text.x = element_text(angle = 90))
# p <- p + scale_fill_manual(values=c('#999999','#E69F00'))
p

df$dif <- df$mod - df$map
df$percentage <- df$dif / df$mod * 100


##### SUBPLOT #####
part1 <- levels(df$country)[1 : 6]
part2 <- levels(df$country)[7 : 17]
part3 <- levels(df$country)[18 : 23]
part4 <- levels(df$country)[24 : 25]

# part1 <- c('AUS', 'BRN', 'BTN', 'TLS')
# part2 <- c('RUS', 'SGP', 'LAO', 'PNG', 'KHM')
# part3 <- c('LKA', 'PRK', 'TWN', 'NPL', 'MYS', 'PAK', 'KOR', 'MMR', 'THA', 'VNM')
# part4 <- c('PHL', 'JPN', 'BGD', 'IDN')
# part5 <- c('IND', 'CHN')

# df_long_p1 <- df_long[which(df_long$country %in% part1), ]
# df_long_p2 <- df_long[which(df_long$country %in% part2), ]
# df_long_p3 <- df_long[which(df_long$country %in% part3), ]
# df_long_p4 <- df_long[which(df_long$country %in% part4), ]

df_long$Part <- 0
df_long$Part[which(df_long$Country %in% part1)] <- 1
df_long$Part[which(df_long$Country %in% part2)] <- 2
df_long$Part[which(df_long$Country %in% part3)] <- 3
df_long$Part[which(df_long$Country %in% part4)] <- 4
# df_long$Part[which(df_long$Country %in% part5)] <- 5

color <- c("#009E73", "#CC79A7")
names(color) <- c('WHO-IG', 'Mapping')
colscale <- scale_fill_manual(name = 'Method', values = color)

p <- ggplot(df_long, aes(x = Country, y = Cases, fill = Method)) + 
    geom_bar(stat = 'identity', position = position_dodge(), alpha = 0.75) + colscale
p <- p + theme(axis.text.x = element_text(angle = 90))
p <- p + facet_wrap(~Part, scale = 'free_y', ncol = 1)
p <- p + ggtitle('Case Compare Mapping vs WHO Incidence Group') +  xlab('Countries') + ylab('Cases')
p

ggsave(filename = 'Cases_Comparison.png', width = 108*2.5, height = 72*2.5, units = 'mm', plot = p)
