# NOTE #
# Extract FOI of entire map based on their countries and compare with WHO-IG
# Visualize in both density and boxplot
# Note that WHO-IG dont have HKG (may be included in CHN)
# Plot and save file
# ---- #

library(ggplot2)
library(grid)
library(gridExtra)

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

##### Read Estimated FOI Values #####
FOI_Estimated <- read.csv("~/DuyNguyen/PythonProjects/OUCRU_JE/Result with Coor/EM/RescaleTVT_Once/Land/Endemic_result_Full_Cov_TVT_Land_400.csv",
                          sep = '\t')
FOI_Estimated <- FOI_Estimated[,-1]

##### Read Country index data #####
Country_Index <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Country_Index.Rds") # index of countries
Coord_Regions_Final <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Generate_Case_Map/Coord_Regions_Final.Rds") # country index of each pixel

##### Extract Country #####
result.country <- Extract_Values_Country(FOI_Estimated, Coord_Regions_Final, Country_Index)
# Fix Low.NPL and High.NPL
result.country$Low.NPL <- c(result.country$Low.NPL, result.country$High.NPL)
names(result.country)[17] <- 'NPL'
result.country$MAC <- NULL
result.country$High.NPL <- NULL

##### Compare to VIMC Posterior: Only some countries required by VIMC #####
# LinkData <- '~/DuyNguyen/RProjects/Rstan_Quan/Result Posterior/Dec06/'
# Listdata <- list.files(LinkData)
# ListCountries <- substr(Listdata, 15, 17)
# Countries_unique <- unique(ListCountries)
# 
# for (idx.country in 1 : length(Countries_unique)){
#     country <- Countries_unique[idx.country]
#     cat('Processing', country, '...\n')
#     idx.list <- which(ListCountries == country)
#     if (length(idx.list) < 2){
#         dat1 <- readRDS(paste0(LinkData, Listdata[idx.list]))
#         if (length(dat1) < 1600){
#             dat1 <- dat1$lambda
#         }
#         dat1.name <- rep(substr(Listdata[idx.list], 15, 17), length(dat1))
#     }else{
#         dat1 <- vector('list', length(idx.list))
#         names(dat1) <- Listdata[idx.list]
#         dat1.name <- rep('temp', 1600 * length(idx.list)) # default 1 R_Stan Posterior has 1600 values
#         for (idx.idx.list in 1 : length(idx.list)){
#             dat1[[idx.idx.list]] <- readRDS(paste0(LinkData, Listdata[idx.list[idx.idx.list]]))
#             if (length(dat1[[idx.idx.list]]) < 1600){
#                 dat1[[idx.idx.list]] <- dat1[[idx.idx.list]]$lambda
#             }
#             dat1.name[((idx.idx.list-1)*1600 + 1) : (idx.idx.list*1600)] <- rep(substr(Listdata[idx.list[idx.idx.list]], 15, 21), 1600)
#         }
#         dat1 <- as.numeric(unlist(dat1))
#     }
#     dat2 <- result.country[[country]]
#     dat2.name <- rep('RF', length(dat2))
#     dat <- data.frame(xx = c(dat1, dat2), yy = c(dat1.name, dat2.name))
#     
#     p <- ggplot(dat,aes(x=xx, y = ..scaled.., fill = yy)) + geom_density(alpha=0.3, position="identity") + 
#         coord_cartesian(xlim=c(quantile(dat$xx, 0.005), quantile(dat$xx, 0.99)))
#     ggsave(filename = paste0('FOI_Dens_', country, '.png'), plot = p)
# }

##### Compare to Journal Posterior from Quan #####
posterior <- readRDS("~/DuyNguyen/JE_model_Quan/results/areas_lambda/ende_24_regions_lambda_extr_or.rds")
select_region <- c(1:6, 11:15, 19:24, 28:30, 32:40, 48) # Quan selection
posterior_select <- posterior[select_region, ]

Countries_unique <- unique(posterior_select$country)
result.posterior <- vector('list', length(Countries_unique))
names(result.posterior) <- Countries_unique

for (idx.country in 1 : length(Countries_unique)){
    country <- Countries_unique[idx.country]
    idx.posterior <- which(posterior_select$country == country)
    result.posterior[[idx.country]] <- unlist(posterior_select[idx.posterior, ]$lambda_extr)
}

##### PLOT DISTRIBUTION #####
All_Countries <- names(result.country)
for (country in All_Countries){
    cat('Processing', country, '...\n')
    if (country != 'HKG'){
        dat1 <- result.posterior[[which(names(result.posterior) == country)]]
        dat2 <- result.country[[which(names(result.country) == country)]]
        dat1.name <- rep('WHO-IG', length(dat1))
        dat2.name <- rep('Mapping', length(dat2))
        
        meandat <- data.frame(mean = c(mean(dat1), mean(dat2)), MeanType = c('WHO-IG', 'Mapping'))
        
        color <- c("#009E73", "#CC79A7")
        names(color) <- c('WHO-IG', 'Mapping')
        colmeanscale <- scale_color_manual(name = 'Mean', values = color)
        colscale <- scale_fill_manual(name = 'Method', values = color)
        
        dat <- data.frame(xx = c(dat1, dat2), Type = c(dat1.name, dat2.name))
    }else{
        cat('QUAN DOES NOT HAVE DATA FOR HKG (MAYBE COMBINE WITH CHN) --> SKIP\n')
        dat2 <- result.country[[which(names(result.country) == country)]]
        dat2.name <- rep('Mapping', length(dat2))
        meandat <- data.frame(mean = mean(dat2), MeanType = 'Mapping')
        color <- c("#CC79A7")
        names(color) <- c('Mapping')
        colmeanscale <- scale_color_manual(name = 'Mean', values = color)
        colscale <- scale_fill_manual(name = 'Method', values = color)
        dat <- data.frame(xx = dat2, Type = dat2.name)
    }
    
    p1 <- ggplot(dat,aes(x=xx, fill = Type)) + geom_density(alpha=0.3, position="identity") + colscale +
        geom_vline(aes(xintercept = mean, color = MeanType), data = meandat, linetype = 'twodash', size = 0.65) + colmeanscale +
        labs(title = paste0('FOI Distribution Comparison - ', country), y = 'Density') + 
        theme(axis.text.x = element_blank(),
              axis.text.y = element_blank(),
              axis.ticks = element_blank(),
              axis.title.x = element_blank(),
              axis.title.y = element_text(size = 14),
              legend.direction = 'horizontal',
              legend.justification = c(1,1), legend.position=c(1,1),
              legend.background = element_rect(fill = 'transparent'),
              plot.title = element_text(size = 16, face = 'bold'))
    # coord_cartesian(xlim=c(quantile(dat$xx, 0.001), quantile(dat$xx, 0.99)))
    
    p2 <- ggplot(dat, aes(x = Type, y = xx, fill = Type)) + geom_boxplot(alpha = 0.3) + coord_flip() + colscale + 
        theme(axis.text.y = element_blank(), 
              axis.ticks.y = element_blank(),
              legend.position = 'none',
              axis.title.y = element_text(size = 14),
              axis.title.x = element_text(size = 14),
              axis.text.x = element_text(size = 13)) + 
        labs(x = 'Method', y = 'FOI')
    
    p3 <- grid.arrange(p1, p2, ncol = 1, heights = c(2, 1))
    
    ggsave(filename = paste0('FOI_Dens_', country, '.png'), width = 108*2.5, height = 72*2.5, units = 'mm', plot = p3) 
    
}

# grid.newpage()
# grid.draw(rbind(ggplotGrob(p), ggplotGrob(p1), size = "last"))


