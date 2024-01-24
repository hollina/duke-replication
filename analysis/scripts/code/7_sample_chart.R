###################################################################################
# Clear memory
rm(list=ls())

###################################################################################
# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(ggplot2, data.table, patchwork, tidyverse)

highlight_color = c(rgb(230, 65, 115, maxColorValue = 255))

# Base size for points and text
base_text_size = 3.5
bigger_text_size  = 4

base_point_size = 3
bigger_point_size = 3.5

###################################################################################
# Read in file

# Baseline
baseline = fread("analysis/output/sr_output_vary_spec.txt")
baseline = baseline[group == "pool" & notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"] 
baseline[, low := b - 1.96*se]
baseline[, high := b + 1.96*se]

# Vary sample
regression_results = fread("analysis/output/sr_output_vary_samp.txt")

# Shift axis function found on stack exchange
shift_axis_x <- function(p, x=0){
  g <- ggplotGrob(p)
  dummy <- data.frame(x=x)
  ax <- g[["grobs"]][g$layout$name == "axis-l"][[1]]
  p + annotation_custom(grid::grobTree(ax, vp = grid::viewport(x=1, width = sum(ax$height))), 
                        xmax=x, xmin=x) +
    geom_vline(aes(xintercept=x), data = dummy) +
    theme(axis.text.y = element_blank(), 
          axis.ticks.y=element_blank())
}
shift_axis_y <- function(p, y=0){
  g <- ggplotGrob(p)
  dummy <- data.frame(y=y)
  ax <- g[["grobs"]][g$layout$name == "axis-b"][[1]]
  p + annotation_custom(grid::grobTree(ax, vp = grid::viewport(y=1, height=sum(ax$height))), 
                        ymax=y, ymin=y) +
    geom_hline(aes(yintercept=y), data = dummy) +
    theme(axis.text.x = element_blank(), 
          axis.ticks.x=element_blank())
}
# Keep subset
regression_results = regression_results[group == "pool"]

# Add CIs 
regression_results[, low := b - 1.96*se]
regression_results[, high := b + 1.96*se]

# Order by size of coef. 
# drop smallest counties, timing of death, start year, end year, stillborn, clean control
regression_results[,drop_smallest := grepl("drop smallest counties", notes)]
regression_results[,timing := grepl("timing of death", notes)]
regression_results[,start_year := grepl("start year", notes)]
regression_results[,end_year := grepl("end year", notes)]
regression_results[,stillborn := grepl("stillborn", notes)]
regression_results[,clean_control := grepl("clean control", notes)]


#regression_results[, order := rank(b)]
regression_results[, order1 := 1:.N]
regression_results[, order2 := ifelse(order1 < 12, order1, order1 + 2)]
regression_results[, order3 := ifelse(order1 < 16 & order1 >= 12, order1 - 17, order2)]

regression_results[, order4 := ifelse(order1 < 26 & order3 >=16, order3 - 5, order3 + 2 - 5)]
regression_results[, order5 := ifelse(order1 < 53 & order1 >=16, order4, order4 + 2 )]

regression_results[, order := ifelse(order1 < 60, order5, order5 - 60 - 12)]
baseline[,order:= -14]
# Generate label 
regression_results[, own_label := sub('.*\\,', '', notes)]

# Append baseline to regression results. 
regression_results = rbind(baseline, regression_results, fill = TRUE)

# Coef plot 
coef_plot = ggplot(data = regression_results
                   , aes(y = -order, x = b)) +
  geom_linerange(aes(xmin = low, xmax = high)) + 
  geom_point(color = "white", size = bigger_point_size) + 
  geom_point(color = "black", size = base_point_size) + 
  geom_linerange(data = subset(regression_results, 
                               notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
                 color = highlight_color, 
                 aes(xmin = low, xmax = high)) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             color = "white", 
             size = bigger_point_size, 
             shape = 15) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             color = highlight_color, 
             size = base_point_size, 
             shape = 15) +
  geom_segment(aes(x = 0, xend = 0, y = 14, yend = -62)) +
  theme_classic() + 
  labs(subtitle = "", 
       x = "",
       y = "") +
  theme(axis.text.y =element_blank(),
        axis.ticks.y = element_blank(),
        axis.line = element_blank()) +
  xlim(-40,40)
coef_plot = coef_plot +  
  annotate("text", x = 1, y = 14, 
           label='bold("Preferred model")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 0) +  
  annotate("text", x = 1, y = 12, 
           label='bold("Include non-Carolina counties")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 0) +  
  annotate("text", x = 27.5, y = 8, 
           label='NC', 
           size = base_text_size, 
           hjust = 1) + 
  annotate("text", x = 1, y = 7, 
           label='bold("Change timing of death")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 0) +  
  annotate("text", x = 1, y = 1, 
           label='bold("Drop smallest X counties")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 0)  +  
  annotate("text", x = 1, y = -12, 
           label='bold("Change first year of panel")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 0) +  
  annotate("text", x = 1, y = -24, 
           label='bold("Change last year of panel")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 0)   +  
  annotate("text", x = 1, y = -53, 
           label='bold("Alter stillbirths/unnamed")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 0) + 
  theme(rect = element_rect(fill = "transparent"))

coef_plot = coef_plot +
  geom_text(data = subset(regression_results, -order > 0), 
                            aes(x = 2.5, 
                                y = -order, 
                                label = own_label), 
                            size = base_text_size, 
            hjust = 0)  +
  geom_text(data = subset(regression_results, -order <= 0 & -order >= -52), 
            aes(x = 2.5, 
                y = -order, 
                label = own_label), 
            size = base_text_size, 
            hjust = 0) +
  geom_text(data = subset(regression_results, -order < -53 & -order != -60), 
            aes(x = 2.5, 
                y = -order, 
                label = own_label), 
            size = base_text_size, 
            hjust = 0)  +
  annotate("text", 
           x = 2.5, 
           y = -61, 
           label = "Include only stillbirths- 1926-1932", 
           size = base_text_size, 
           hjust = 0) + 
  theme(axis.text=element_text(size = 12))

coef_plot = shift_axis_y(coef_plot, -62) 

coef_plot = coef_plot + 
  annotate("text", x = 0, y = -65, 
           label='Percent reduction', 
           size = 5, 
           hjust = .5)

coef_plot

#ggsave(filename = "analysis/output/main/figure_5b_sample_chart.png", 
#       plot =  coef_plot, 
#       width = 6, 
#       height = 12.75)

ggsave(filename = "analysis/output/main/figure_5b_sample_chart.pdf", 
       plot =  coef_plot, 
       width = 6, 
       height = 12.75)

