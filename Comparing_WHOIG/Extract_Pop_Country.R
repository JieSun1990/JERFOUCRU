# NOTE #
# Compare population between 2 sources (WHO-IG and RF)
# Note that remove MAC in RF (since in the mapping MAC is inside CHN)
# Also add HKG to CHN (since WHO-IG dont have HKG, might be included in CHN also)
# ---- #

# library(sp)
# library(raster)
# library(rgdal)
# library(rgeos)

##### Read Pop Map Data (Adjusted to match UN) #####
# The 4 following lines is the RF population (not adjusted yet) --> if we want to compare the original RF pop, then use the 4 below lines
# Endemic_DF_WP_Imputed_Land <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Data JE/Data_RF/Endemic_DF_WP_Full_Cov_Imputed_Land.Rds")
# idx_col_pop <- which(colnames(Endemic_DF_WP_Imputed_Land) == 'Pop_Count_WP_SEDAC_2015')
# df.pop <- Endemic_DF_WP_Imputed_Land[, c(1, 2, idx_col_pop)]
# rm(Endemic_DF_WP_Imputed_Land)

# Adjusted RF Pop
df.pop <- readRDS('~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Adjusted_Pop_Map.Rds')
colnames(df.pop) <- c('x', 'y', 'Pop')

# ##### Read Country index data #####
Country_Index <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Country_Index.Rds") # index of countries
Coord_Regions_Final <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Coord_Regions_Final.Rds") # index of pixel

##### Read VIMC Pop data #####
# # naive_pop_1950_2100_Dec06 <- read.csv("DuyNguyen/RProjects/Rstan_Quan/Data/VIMC new run deadline 21th dec/naive_pop_1950_2100_Dec06.csv")
# naive_pop_1950_2100_Dec06 <- read.csv("DuyNguyen/RProjects/Rstan_Quan/NaivePop Country/NaivePop_All_Dec06.csv")
# # vimc.pop <- naive_pop_1950_2100_Dec06[, c('country_code', 'age_from', 'age_to', 'X2015')]
# vimc.pop <- naive_pop_1950_2100_Dec06[, c('country', 'age_from', 'age_to', 'X2015')]
# colnames(vimc.pop) <- c('country_code', 'age_from', 'age_to', 'X2015')
# rm(naive_pop_1950_2100_Dec06)
#
# ##### Create Entire Pop VIMC for each country #####
# vimc.pop$country_code <- as.character(vimc.pop$country_code)
# countries.vimc <- unique(vimc.pop$country_code)
# # countries.vimc <- c("BGD", "BTN", "CHN", "IDN", "IND", "KHM", "LAO", "LKA", "MMR",
# #                     "NPL", "PAK", "PHL", "PNG", "PRK", "TLS", "VNM")
# entirepop_VIMC <- data.frame(country = countries.vimc, totalpop = 0)
# entirepop_VIMC$country <- as.character(entirepop_VIMC$country)
# for (idx.country in 1 : length(countries.vimc)){
#     country <- countries.vimc[idx.country]
#     pop <- sum(vimc.pop$X2015[which(vimc.pop$country_code == country)])
#     entirepop_VIMC$totalpop[idx.country] <- pop
# }
# 
# # adjust IDN.Low, IDN.High
# idx.low <- which(entirepop_VIMC$country == 'IDN.Low')
# idx.high <- which(entirepop_VIMC$country == 'IDN.High')
# entirepop_VIMC$totalpop[idx.low] <- sum(entirepop_VIMC$totalpop[c(idx.low, idx.high)])
# entirepop_VIMC$country[idx.low] <- 'IDN'
# entirepop_VIMC <- entirepop_VIMC[-idx.high, ]
# 
# # adjust IND.Low, IND.Medium, IND.High
# idx.low <- which(entirepop_VIMC$country == 'IND.Low')
# idx.medium <- which(entirepop_VIMC$country == 'IND.Medium')
# idx.high <- which(entirepop_VIMC$country == 'IND.High')
# entirepop_VIMC$totalpop[idx.low] <- sum(entirepop_VIMC$totalpop[c(idx.low, idx.medium, idx.high)])
# entirepop_VIMC$country[idx.low] <- 'IND'
# entirepop_VIMC <- entirepop_VIMC[-c(idx.high, idx.medium), ]
# countries.vimc <- unique(entirepop_VIMC$country)




##### Read WHO-IG Population Data (collected by Quan) #####
pop_WHOIG <- readRDS("~/DuyNguyen/JE_model_Quan/data/population/Naive_pop_24ende_1950_2015.rds")
pop_WHOIG <- pop_WHOIG[ ,c(1, which(colnames(pop_WHOIG) == 'X2015'))]
pop_WHOIG$region <- as.character(pop_WHOIG$region)
foi_data1 <- readRDS("~/DuyNguyen/JE_model_Quan/results/areas_lambda/ende_24_regions_lambda_extr_or.rds")
select_region <- c(1:6, 11:15, 19:24, 28:30, 32:40, 48) # Quan decision
select_region <- as.character(foi_data1$region[select_region])
pop_WHOIG <- pop_WHOIG[which(pop_WHOIG$region %in% select_region),]

countries_data1 <- unique(pop_WHOIG$region)
entirepop_WHOIG <- data.frame(country = countries_data1, totalpop = 0)
entirepop_WHOIG$country <- as.character(entirepop_WHOIG$country)
for (idx.country in 1 : length(countries_data1)){
    country <- countries_data1[idx.country]
    pop <- sum(pop_WHOIG$X2015[which(pop_WHOIG$region == country)])
    entirepop_WHOIG$totalpop[idx.country] <- pop
}

# adjust IDN.Low, IDN.High
idx.low <- which(entirepop_WHOIG$country == 'Low.IDN')
idx.high <- which(entirepop_WHOIG$country == 'High.IDN')
entirepop_WHOIG$totalpop[idx.low] <- sum(entirepop_WHOIG$totalpop[c(idx.low, idx.high)])
entirepop_WHOIG$country[idx.low] <- 'IDN'
entirepop_WHOIG <- entirepop_WHOIG[-idx.high, ]

# adjust IND.Low, IND.Medium, IND.High
idx.low <- which(entirepop_WHOIG$country == 'Low.IND')
idx.medium <- which(entirepop_WHOIG$country == 'Medium.IND')
idx.high <- which(entirepop_WHOIG$country == 'High.IND')
entirepop_WHOIG$totalpop[idx.low] <- sum(entirepop_WHOIG$totalpop[c(idx.low, idx.medium, idx.high)])
entirepop_WHOIG$country[idx.low] <- 'IND'
entirepop_WHOIG <- entirepop_WHOIG[-c(idx.high, idx.medium), ]
countries_data1 <- unique(entirepop_WHOIG$country)

# adjust Low.NPL and High.NPL
idx_low <- which(entirepop_WHOIG$country == 'Low.NPL')
idx_high <- which(entirepop_WHOIG$country == 'High.NPL')
entirepop_WHOIG$totalpop[idx_low] <- entirepop_WHOIG$totalpop[idx_low] + entirepop_WHOIG$totalpop[idx_high]
entirepop_WHOIG$country[idx_low] <- 'NPL'
entirepop_WHOIG <- entirepop_WHOIG[-idx_high, ]

# adjust Low.CHN and High.CHN
idx_low <- which(entirepop_WHOIG$country == 'Low.CHN')
idx_high <- which(entirepop_WHOIG$country == 'High.CHN')
entirepop_WHOIG$totalpop[idx_low] <- entirepop_WHOIG$totalpop[idx_low] + entirepop_WHOIG$totalpop[idx_high]
entirepop_WHOIG$country[idx_low] <- 'CHN'
entirepop_WHOIG <- entirepop_WHOIG[-idx_high, ]

# adjust name of total_TWN
entirepop_WHOIG$country[24] <- 'TWN'





##### Create RF Population (Adjusted) Dataframe for each country #####
entirepop_RF <- data.frame(country = Country_Index, totalpop = 0)
entirepop_RF$country <- as.character(entirepop_RF$country)
for (idx.country in 1 : length(Country_Index)){
    idx_point <- which(Coord_Regions_Final$regions == idx.country)
    if (length(idx_point) > 0){
        pop <- sum(df.pop$Pop[idx_point])
        entirepop_RF$totalpop[idx.country] <- pop
    }
}
# Fix problem Low.NPL + High.NPL
idx_low <- which(entirepop_RF$country == 'Low.NPL')
idx_high <- which(entirepop_RF$country == 'High.NPL')
entirepop_RF$totalpop[idx_low] <- entirepop_RF$totalpop[idx_low] + entirepop_RF$totalpop[idx_high]
entirepop_RF$country[idx_low] <- 'NPL'
entirepop_RF <- entirepop_RF[-idx_high, ]
# Remove MAC
idx_MAC <- which(entirepop_RF$country == 'MAC')
entirepop_RF <- entirepop_RF[-idx_MAC, ]
# Add HKG to CHN
idx_HKG <- which(entirepop_RF$country == 'HKG')
idx_CHN <- which(entirepop_RF$country == 'CHN')
# Add HKG pop to CHN pop (if we dont want to add, only remove HKG out of dataframe --> comment the next line)
entirepop_RF$totalpop[idx_CHN] <- entirepop_RF$totalpop[idx_CHN] + entirepop_RF$totalpop[idx_HKG] 
# Remove HKG
entirepop_RF <- entirepop_RF[-idx_HKG, ]





##### Create DF Compare #####
Countries <- as.character(entirepop_RF$country)
df <- data.frame(country = Countries, mod = 0, map = 0)
df$country <- as.character(df$country)
for (idx in 1 : nrow(df)){
    country <- df$country[idx]
    idx_map <- which(entirepop_RF$country == country)
    idx_mod <- which(entirepop_WHOIG$country == country)
    df$map[idx] <- entirepop_RF$totalpop[idx_map]
    df$mod[idx] <- entirepop_WHOIG$totalpop[idx_mod]
}
df$map <- round(df$map)
df$mod <- round(df$mod)

df$country <- factor(df$country, levels = unique(df$country[order(df$mod)]), ordered = TRUE) # order based on modelling values (WHO-IG)
# lv <- c('AUS', 'BRN', 'BTN', 'TLS', 'RUS', 'SGP', 'LAO', 'PNG', 'KHM',
#         'LKA', 'PRK', 'TWN', 'NPL', 'MYS', 'PAK', 'KOR', 'MMR', 'THA', 'VNM',
#         'PHL', 'JPN', 'BGD', 'IDN', 'IND', 'CHN')
# df$country <- factor(df$country, levels = lv, ordered = TRUE) # order based on specific level lv

df_long <- gather(df, method, cases, mod, map, factor_key = TRUE)
colnames(df_long) <- c('Country', 'Method', 'Cases')
df_long$Method <- as.character(df_long$Method)
df_long$Method[which(df_long$Method == 'mod')] <- 'WHO-IG'
df_long$Method[which(df_long$Method == 'map')] <- 'Mapping'

##### SUBPLOT #####
# Divided Manually based on the cases --> divided into subgroup in order to make easier to see the plot (y-axis varies alot between countries)
part1 <- levels(df$country)[1 : 4]
part2 <- levels(df$country)[5 : 9]
part3 <- levels(df$country)[10 : 19]
part4 <- levels(df$country)[20 : 23]
part5 <- levels(df$country)[24 : 25]

df_long$Part <- 0
df_long$Part[which(df_long$Country %in% part1)] <- 1
df_long$Part[which(df_long$Country %in% part2)] <- 2
df_long$Part[which(df_long$Country %in% part3)] <- 3
df_long$Part[which(df_long$Country %in% part4)] <- 4
df_long$Part[which(df_long$Country %in% part5)] <- 5

color <- c("#009E73", "#CC79A7")
names(color) <- c('WHO-IG', 'Mapping')
colscale <- scale_fill_manual(name = 'Method', values = color)

p <- ggplot(df_long, aes(x = Country, y = Cases, fill = Method)) + 
    geom_bar(stat = 'identity', position = position_dodge(), alpha = 0.75) + colscale
p <- p + facet_wrap(~Part, scale = 'free_y', ncol = 1)
p <- p + theme(axis.text.x = element_text(angle = 90))
p <- p + ggtitle('Population Compare Mapping vs WHO Incidence Group') +  xlab('Countries') + ylab('Population')
p

# SAVE FILE
# ggsave(filename = 'Pop_Comparison.png', width = 108*2.5, height = 72*2.5, units = 'mm', plot = p)