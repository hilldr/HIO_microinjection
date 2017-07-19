## R script for analyzing HIO FITC-dextran permeability data
## David R. Hill

## run imagej-threshold-quant.sh to generate results file
## prior to analysis in R

## DATA WRANGLING ##############################################################
## load raw data output into R
data <- readr::read_delim(file = "../results/threshold_results.txt",
                          delim = "\t",
                          col_names = TRUE)

## parse metadata from file names 
## NOTE: This step may vary significantly depending on your imaging
## software and file naming scheme. Below is a general example
## illustrating one approach

## remove uninformative characters
data$name <- gsub(pattern = "HIO_",
                  replacement = "",
                  data$Filename) # retain filename for reference
data$name <- gsub(pattern = ".tif",
                  replacement = "",
                  data$name)
data$name <- gsub(pattern = ".png",
                  replacement = "",
                  data$name)
data$name <- gsub(pattern = "R3D",
                  replacement = "",
                  data$name)
data$name <- gsub(pattern = "w523",
                  replacement = "",
                  data$name)
data$name <- gsub(pattern = "w525",
                  replacement = "",
                  data$name)
data$name <- gsub(pattern = "___",
                  replacement = "_",
                  data$name)
data$name <- gsub(pattern = "t",
                  replacement = "",
                  data$name)

## split string into distinct data columns
## date the experiment was conducted
data$experiment_date <- as.factor(stringr::str_split_fixed(string = data$name,
                                                 pattern = "_", n = 3)[,1])
data$experiment_date <- gsub(pattern = "0",
                  replacement = "",
                  data$experiment_date)

## number indicating the specific HIO in image
data$HIO <- as.numeric(stringr::str_split_fixed(string = data$name,
                                     pattern = "_", n = 3)[,2])
## frame number in sequence, with frame 1 = T0
data$frame <- as.numeric(stringr::str_split_fixed(string = data$name,
                                       pattern = "_", n = 3)[,3])

## data manipulation
## convert NaN values to 0
is.nan.data.frame <- function(x) {
    do.call(cbind, lapply(x, is.nan))}
data$Mean[is.nan.data.frame(data$Mean)] <- 0

## subset baseline measurement as separate dataframe
baseline <- subset(data, data$frame == 1)
baseline$t0 <- baseline$Mean
baseline <- dplyr::select(baseline, HIO, experiment_date, t0)

## merge column with baseline measurements for normalization
data <- dplyr::left_join(data, baseline, by = c("HIO", "experiment_date"))

## caclulate normalized fluorescence
data$normalized <- data$Mean/data$t0

## load sample key with experiment data and HIO group assignments
groups <- readr::read_csv(file = '../data/sample_key.csv', col_names = TRUE)
groups$experiment_date <- as.character(groups$experiment_date)

## merge with main data table
data <- dplyr::left_join(data, groups, by = c("HIO", "experiment_date"))

## calculate time
## experiment from 01/2015 used 15 min interval. Exp from 07/2015 used 10 min interval
data$min <- ifelse(data$experiment_date == "11515", (data$frame*15)-15,(data$frame*10)-10)
## convert to hours
data$hr <- data$min/60

## generate group summary statistics for plotting
library(magrittr)
data_mean <- dplyr::group_by(data, treatment, hr) %>%
    dplyr::summarise(mean = mean(normalized), 
                     stdev = sd(normalized), #standard deviation
                     num = n(),
                     sem = sd(normalized)/n(),
                     iqr = IQR(normalized), #inter-quartile region
                     min = min(normalized),
                     max = max(normalized),
                     median = median(normalized))

## statistical analysis
data_auc <- dplyr::group_by(data, HIO, experiment_date) %>%
    dplyr::summarise(auc = flux::auc(hr, normalized)) #area under curve
data_auc$cl <- 1/data_auc$auc #clearance rate
data_auc$ke = data_auc$cl/(1/1) # elimination rate constant. Vd = 1 for normalized T=0 FITC
data_auc$thalf = logb(2,2)/data_auc$ke #t1/2

## generate summary statistics for thalf data
data.thalf <- dplyr::left_join(data_auc, groups, by = c("HIO", "experiment_date")) %>% 
    dplyr::select(treatment, thalf)
data.thalf.stats <- dplyr::group_by(data.thalf, treatment) %>%
    dplyr::summarise(mean = mean(thalf), 
                     stdev = sd(thalf), #standard deviation
                     num = n(),
                     sem = sd(thalf)/n(),
                     min = min(thalf),
                     max = max(thalf)) %>%
    dplyr::mutate(lower.ci = mean - qt(1 - (0.05/2), num - 1) * sem,
                   upper.ci = mean + qt(1 - (0.05/2), num - 1) * sem)

## student's t-tests
## egta vs. control
test1 <- t.test(data.thalf[data.thalf$treatment == "Control",]$thalf,
                data.thalf[data.thalf$treatment == "EGTA",]$thalf)$p.value
## tcda vs. control
test2 <- t.test(data.thalf[data.thalf$treatment == "Control",]$thalf,
                data.thalf[data.thalf$treatment == "TcdA",]$thalf)$p.value
## tcda vs. egta
test3 <- t.test(data.thalf[data.thalf$treatment == "EGTA",]$thalf,
                data.thalf[data.thalf$treatment == "TcdA",]$thalf)$p.value

## Plotting ####################################################################
library(ggplot2)
## Import Figure 4A and convert to vector graphics
library(grid)
library(gridSVG)
library(grConvert)
library(grImport2)
library(gridExtra)

if (file.exists("../img/FITC-HIOs-cairo.svg.Rdata") == TRUE) {
    load(file = "../img/FITC-HIOs-cairo.svg.Rdata")
} else {    
    ##https://www.stat.auckland.ac.nz/~paul/Reports/Rlogo/Rlogo.html
    grConvert::convertPicture("../img/FITC-HIOs.svg", "../img/FITC-HIOs-cairo.svg")
    ## this step takes a while
    figure1a <- grImport2::readPicture("../img/FITC-HIOs-cairo.svg")
    save(figure1a, file = "../img/FITC-HIOs-cairo.svg.Rdata")
    load(file = "../img/FITC-HIOs-cairo.svg.Rdata")
}

fig4a <- gTree(children = gList(pictureGrob(figure1a, ext = "gridSVG"))) 

fig4a <- qplot(1:100, 1:100, alpha = I(0)) +
    theme_bw() +
    annotation_custom(fig4a, xmin = -Inf,
                      xmax = Inf,
                      ymin = -Inf,
                      ymax = Inf) +
    ggtitle("A") + coord_fixed(ratio = 1) +
    theme(panel.grid.major = element_blank(),
                   panel.grid.minor = element_blank(),
                   panel.border = element_blank(),
                   axis.text.x = element_blank(),
                   axis.text.y = element_blank(),
                   axis.ticks  =  element_blank(),
                   axis.title.x = element_blank(),
                   axis.title.y = element_blank(),
                   plot.title  =  element_text(size = 45,
                                             face = "bold",
                                             hjust  =  0), 
                   legend.position = "none")

## Setup for figure 4B
fig4b <- ggplot(data = data_mean, aes(x = hr, y = mean, fill = treatment)) +
    geom_errorbar(aes(ymin = mean - sem,
                      ymax = mean + sem,
                      color = treatment),
                  width = 0, size = 1) +
    geom_point(shape = 21, size = 10, color = "white", stroke = 1) +
    scale_x_continuous(breaks = seq(0,24,1), limits = c(0,10)) +
    xlab("Time (h)") + ylab("Normalized FITC-dextran intensity") +
    ggtitle("B") +
    ## plot theme
    theme(axis.text.x = element_text(size = 32,
                                     angle = 0,
                                     hjust = 0.5,
                                     face = "bold"),
          axis.text.y = element_text(size = 32,
                                     face = "bold",
                                     hjust = 1),
          legend.position = c(0.1,0.15),
          legend.key = element_rect(fill = "white"),
	  legend.text = element_text(size = 32,
                                     face = "bold"),
          legend.key.size = unit(1.5, "cm"),				    
          panel.background = element_rect(fill = "white"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.title = element_text(size = 36,
                                    face = "bold"),
          axis.title.y = element_text(vjust = 1.5),
          axis.title.x = element_text(vjust = -0.5),
          legend.title = element_blank(),
          panel.border = element_rect(fill = NA,
                                      color = "black",
                                      size = 1),
          plot.title = element_text(size = 45,
                                    face = "bold",
                                    hjust = 0)
          )

## setup multipanel PDF plot
layout <- rbind(c(rep(1, times = 4),rep(2, times = 5)))
pdf(file = "../results/figure4.pdf", width = 8800/300, height = 4000/300, onefile = FALSE)
gridExtra::grid.arrange(fig4a,fig4b, layout_matrix = layout)
dev.off()
