###################################################################################
# Clear memory
rm(list=ls())

###################################################################################
# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(ggplot2, data.table, patchwork, tidyverse)

# Correct pink color for highlighting
highlight_color = c(rgb(230, 65, 115, maxColorValue = 255))

# Base size for points and text
base_text_size = 3.5
bigger_text_size  = 4

base_point_size = 3
bigger_point_size = 3.5

base_dp_size = 3
bigger_dp_size = 3.5

# Shift access function
shift_axis_x <- function(p, x=0){
  g <- ggplotGrob(p)
  dummy <- data.frame(x=x)
  ax <- g[["grobs"]][g$layout$name == "axis-l"][[1]]
  p + annotation_custom(grid::grobTree(ax, vp = grid::viewport(x=1, width = sum(ax$height))), 
                        xmax=x, xmin=x) +
    geom_vline(aes(xintercept=x), data = dummy) +
    theme(axis.text.y = element_blank(), 
          axis.ticks.y = element_blank())
}
###################################################################################
# Create single data.table with all results

# Read in file
regression_results = fread("analysis/output/sr_output_vary_spec.txt", encoding = 'UTF-8')

# Create binary for each item in notes list. 
regression_results[,poisson := grepl("poisson", notes)]
regression_results[,ols := grepl("sr, ols,", notes)]
regression_results[,CS := grepl("Callaway", notes)]
regression_results[,mundlak := grepl("mundlak", notes)]
regression_results[,stacked := grepl("stacked", notes)]

regression_results[,death_count := grepl("death_count", notes)]
regression_results[,death_rate := grepl("[^ln_]death_rate", notes)]
regression_results[,ln_death_rate := grepl("ln_death_rate", notes)]

regression_results[,countyFE := grepl("Ycounty", notes)]
regression_results[,yearFE := grepl("Yyear", notes)]
regression_results[,controls := grepl("Ycontrols", notes)]
regression_results[,weights := grepl("Yweights", notes)]


# Add CIs 
regression_results[, low := b - 1.96*se]
regression_results[, high := b + 1.96*se]

# Create subset
regression_results_pooled = regression_results[group == "pool"]
setnames(regression_results_pooled, 'N', 'pooled_N') 

regression_results_white = regression_results[group == "white"]
regression_results_white = regression_results_white[,.(notes, b, low, high, N)]
setnames(regression_results_white, 'b', 'white_b') 
setnames(regression_results_white, 'low', 'white_low') 
setnames(regression_results_white, 'high', 'white_high') 
setnames(regression_results_white, 'N', 'white_N') 

regression_results_black = regression_results[group == "black"]
regression_results_black = regression_results_black[,.(notes, b, low, high, N)]
setnames(regression_results_black, 'b', 'black_b') 
setnames(regression_results_black, 'low', 'black_low') 
setnames(regression_results_black, 'high', 'black_high') 
setnames(regression_results_black, 'N', 'black_N') 

regression_results = merge(regression_results_pooled, regression_results_white)
regression_results = merge(regression_results, regression_results_black)

# Order by size of coef. 
regression_results[, order := frank(b, ties.method = "first")]

# Coef plot 
coef_plot = ggplot(data = regression_results
                   , aes(y = b, x = order)) +
  geom_linerange(aes(ymin = low, ymax = high)) + 
  geom_point(color = "white", size = bigger_point_size) + 
  geom_point(color = "black", size = base_point_size) + 
  geom_linerange(data = subset(regression_results, 
                               notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
                 color = highlight_color, 
                 aes(ymin = low, ymax = high)) + 
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
  geom_segment(aes(x = 0, xend = 12, y = 0, yend = 0)) +
  geom_segment(aes(x = 0, xend = 0, y = 0, yend = -25)) +
  theme_classic() + 
  labs(subtitle = "", 
       x = "",
       y = "") +
  theme(axis.text.x =element_blank(),
        axis.ticks.x = element_blank(),
        axis.line = element_blank()) + 
  xlim(-3.5, 12)  +
  ylim(-30, 2)  + 
  annotate("text", x = -1.5, y = -4.5, 
           label='Percent reduction', 
           size = 4.5, 
           hjust = 1, 
           angle = 90) + 
  theme(axis.text=element_text(size = 10))

coef_plot = shift_axis_x(coef_plot, 0) 
coef_plot

dot_plot  = ggplot(data = subset(regression_results, 
                                 notes != "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")
                   , aes(y = 1, x = order, fill = as.factor(countyFE))) +
  geom_point(size = bigger_dp_size, 
             shape = 21) +
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             color = 'black', 
             size = bigger_dp_size, 
             shape = 15) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             color = highlight_color, 
             size = base_dp_size, 
             shape = 15) + 
  annotate("text", x = .5, y = 1, 
           label= 'County FE', 
           size = base_text_size, 
           hjust = 1) + 
  geom_point(data = subset(regression_results, 
                           notes != "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")
             , aes(y = 0, x = order, fill = as.factor(yearFE)), 
             size = bigger_dp_size, 
             shape = 21)  +
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = 0, x = order, fill = as.factor(yearFE)),
             color = "black", 
             size = bigger_dp_size, 
             shape = 15) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = 0, x = order, fill = as.factor(yearFE)),
             color = highlight_color, 
             size = base_dp_size, 
             shape = 15) +
  annotate("text", x = .5, y = 0, 
           label='Year FE', 
           size = base_text_size, 
           hjust = 1) + 
  geom_point(data = subset(regression_results, 
                           notes != "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")
             , aes(y = -1, x = order, fill = as.factor(controls)), 
             size = bigger_dp_size, 
             shape = 21)  +
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -1, x = order, fill = as.factor(controls)),
             color = "black", 
             size = bigger_dp_size, 
             shape = 15) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -1, x = order, fill = as.factor(controls)),
             color = highlight_color, 
             size = base_dp_size, 
             shape = 15) + 
  annotate("text", x = .5, y = -1, 
           label='Controls', 
           size = base_text_size, 
           hjust = 1) + 
  geom_point(data = subset(regression_results, 
                           notes != "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")
             , aes(y = -2, x = order, fill = as.factor(weights)), 
             size = bigger_dp_size, 
             shape = 21)  +
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -2, x = order, fill = as.factor(weights)),
             color = "black", 
             size = bigger_dp_size, 
             shape = 15) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -2, x = order, fill = as.factor(weights)),
             color = highlight_color, 
             size = base_dp_size, 
             shape = 15) + 
  annotate("text", x = .5, y = -2, 
           label='Weights', 
           size = base_text_size, 
           hjust = 1) + 
  geom_point(data = subset(regression_results, 
                           notes != "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")
             , aes(y = -5, x = order, fill = as.factor(death_rate)), 
             size = bigger_dp_size, 
             shape = 21)  +
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -5, x = order, fill = as.factor(death_rate)),
             color = "black", 
             size = bigger_dp_size, 
             shape = 15) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -5, x = order, fill = as.factor(death_rate)),
             color = highlight_color, 
             size = base_dp_size, 
             shape = 15) + 
  annotate("text", x = .5, y = -5, 
           label='Death rate', 
           size = base_text_size, 
           hjust = 1) +  
  geom_point(data = regression_results
             , aes(y = -6, x = order, fill = as.factor(death_count)), 
             size = bigger_dp_size, 
             shape = 21)  +
  annotate("text", x = .5, y = -6, 
           label='Death count', 
           size = base_text_size, 
           hjust = 1) + 
  geom_point(data = regression_results
             , aes(y = -7, x = order, fill = as.factor(ln_death_rate)), 
             size = bigger_dp_size, 
             shape = 21)  +
  annotate("text", x = .5, y = -7, 
           label='ln(Death rate)', 
           size = base_text_size, 
           hjust = 1) + 
  geom_point(data = subset(regression_results, 
                           notes != "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights")
             , aes(y = -10, x = order, fill = as.factor(poisson)), 
             size = bigger_dp_size, 
             shape = 21)  +
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -10, x = order, fill = as.factor(poisson)),
             color = "black", 
             size = bigger_dp_size, 
             shape = 15) + 
  geom_point(data = subset(regression_results, 
                           notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
             aes(y = -10, x = order, fill = as.factor(poisson)),
             color = highlight_color, 
             size = base_dp_size, 
             shape = 15) + 
  annotate("text", x = .5, y = -10, 
           label='Poisson', 
           size = base_text_size, 
           hjust = 1) + 
  geom_point(data = regression_results
             , aes(y = -11, x = order, fill = as.factor(stacked)), 
             size = bigger_dp_size, 
             shape = 21)  +
  annotate("text", x = .5, y = -11, 
           label='Stacked-Poisson', 
           size = base_text_size, 
           hjust = 1) +
  geom_point(data = regression_results
             , aes(y = -12, x = order, fill = as.factor(ols)), 
             size = bigger_dp_size, 
             shape = 21)  +
  annotate("text", x = .5, y = -12, 
           label='TWFE (OLS)', 
           size = base_text_size, 
           hjust = 1) +
  geom_point(data = regression_results
             , aes(y = -13, x = order, fill = as.factor(CS)), 
             size = bigger_dp_size, 
             shape = 21)  +
  annotate("text", x = .5, y = -13, 
           label='Callaway and Sant\'Anna', 
           size = base_text_size*.9, 
           hjust = 1) + 
  geom_point(data = regression_results
             , aes(y = -14, x = order, fill = as.factor(mundlak)), 
             size = bigger_dp_size, 
             shape = 21)  +
  annotate("text", x = .5, y = -14, 
           label='eTWFE-Poisson', 
           size = base_text_size, 
           hjust = 1) +
  theme_classic() +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.line = element_blank(), 
        legend.position="none")  +
  scale_fill_manual(values=c("TRUE"="black", "FALSE"="white")) +
  labs(x = "", 
       y = "") + 
  xlim(-3.5, 12) 

dot_plot


dot_plot = dot_plot + 
  annotate("text", x = .5, y = 2.25, 
           label='bold("Spec. includes:")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 1) + 
  annotate("text", x = .5, y = -3.75, 
           label='bold("Dependent variable:")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 1) + 
  annotate("text", x = .5, y = -8.75, 
           label='bold("Estimator:")', 
           parse = TRUE, 
           size = bigger_text_size, 
           hjust = 1)
dot_plot
##############################################3
# White

# Coef plot 
white_coef_plot = ggplot(data = regression_results
                   , aes(y = white_b, x = order)) +
  geom_linerange(aes(ymin = white_low, ymax = white_high)) + 
  geom_point(color = "white", size = bigger_point_size) + 
  geom_point(color = "black", size = base_point_size) + 
  geom_linerange(data = subset(regression_results, 
                               notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
                 color = highlight_color, 
                 aes(ymin = white_low, ymax = white_high)) + 
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
  geom_segment(aes(x = 0, xend = 12, y = 0, yend = 0)) +
  geom_segment(aes(x = 0, xend = 0, y = 2, yend = -25)) +
  theme_classic() + 
  labs(subtitle = "", 
       x = "",
       y = "") +
  theme(axis.text.x =element_blank(),
        axis.ticks.x = element_blank(),
        axis.line = element_blank()) + 
  xlim(-3.5, 12)  +
  ylim(-25, 5)  + 
  annotate("text", x = -1.5, y = -1, 
           label='Percent reduction', 
           size = 4.5, 
           hjust = 1, 
           angle = 90) + 
  theme(axis.text=element_text(size = 10))
white_coef_plot
white_coef_plot = shift_axis_x(white_coef_plot, 0) 
white_coef_plot

#############################################################
# Black Coef plot 
black_coef_plot = ggplot(data = regression_results
                   , aes(y = black_b, x = order)) +
  geom_linerange(aes(ymin = black_low, ymax = black_high)) + 
  geom_point(color = "white", size = bigger_point_size) + 
  geom_point(color = "black", size = base_point_size) + 
  geom_linerange(data = subset(regression_results, 
                               notes == "sr, poisson, death_rate, Ycounty, Yyear, Ycontrols, Yweights"), 
                 color = highlight_color, 
                 aes(ymin = black_low, ymax = black_high)) + 
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
  geom_segment(aes(x = 0, xend = 12, y = 0, yend = 0)) +
  geom_segment(aes(x = 0, xend = 0, y = 0, yend = -40)) +
  theme_classic() + 
  labs(subtitle = "", 
       x = "",
       y = "") +
  theme(axis.text.x =element_blank(),
        axis.ticks.x = element_blank(),
        axis.line = element_blank()) + 
  xlim(-3.5, 12)  +
  ylim(-35, 7)  + 
  annotate("text", x = -1.5, y = -3, 
           label='Percent reduction', 
           size = 4.5, 
           hjust = 1, 
           angle = 90) + 
  theme(axis.text=element_text(size = 10))
black_coef_plot
black_coef_plot = shift_axis_x(black_coef_plot, 0) 
black_coef_plot

# Combine these

coef_plot = coef_plot + 
  ggtitle('Pooled') +
  theme(plot.title = element_text(hjust = 0.25))

black_coef_plot = black_coef_plot + 
  ggtitle('Black') +
  theme(plot.title = element_text(hjust = 0.25))

white_coef_plot = white_coef_plot + 
  ggtitle('White') +
  theme(plot.title = element_text(hjust = 0.25))

combined_plot  = coef_plot /  black_coef_plot / white_coef_plot / dot_plot

to_save = combined_plot +  
  plot_layout(heights = c(2, 2, 2, 3.5))

#ggsave(filename = "analysis/output/main/figure_5a_spec_chart_combined.png", 
#       plot =  to_save, 
#       width = 6, 
#       height = 12)

ggsave(filename = "analysis/output/main/figure_5a_spec_chart_combined.pdf", 
       plot =  to_save, 
       width = 6, 
       height = 12)
