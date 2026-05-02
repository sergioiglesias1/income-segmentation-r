# PCA
source("config.R")
load("C:/Users/Usuario/Downloads/repo_R/data/.workspace.RData")

library(ggplot2)
library(scatterplot3d)
library(moments)
library(reshape2)

if (!dir.exists(PLOTS1_DIR)) dir.create(PLOTS1_DIR, recursive = T)

### Distribution analysis for Key Economic Indicators ###
key_eco_indicators <- c("gdp_per_capita", "internet_users", "life_expectancy")

for (col in key_eco_indicators) {
  vals  <- X[[col]]

  m <- mean(vals)
  v <- var(vals)
  s <- sd(vals)

  skew  <- round(moments::skewness(vals), 3)
  kurt  <- round(moments::kurtosis(vals), 3)
  
  png(file.path(PLOTS1_DIR, paste0("distr_", col, ".png")), width = 800, height = 600)
  
  hist(vals,
       main   = paste("Distribution Analysis:", col),
       xlab   = col, ylab   = "Density",
       col    = "skyblue", border = "white", probability = T)
  
  lines(density(vals), col = "red", lwd = 3)
  curve(dnorm(x, m, s), add = T, col = "blue", lwd = 2, lty = 2)
  
  # Log-Normal distribution (typical for economic data if > 0)
  if(all(vals > 0)) {
    mu_log <- log(m^2 / sqrt(v + m^2))
    sd_log <- sqrt(log(1 + v / m^2))
    curve(dlnorm(x, mu_log, sd_log), add = T, col = "darkgreen", lwd = 2, lty = 3)
  }
  
  legend("topright", legend = c("Empirical", "Normal", "Log-Normal"),
         col = c("red", "blue", "darkgreen"), lwd = 2, bty = "n")
  dev.off()
}

### Correlation Matrix ###
png(file.path(PLOTS1_DIR, "correlation_matrix.png"), width = 500, height = 500)
corx <- reshape2::melt(cor(X))
p_cor <- ggplot(corx, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0) +
  theme_minimal() + labs(title = "Economic Indicators Correlation")
print(p_cor)
dev.off()

### PCA & Manual eigen-decomposition ###
A               <- t(X_scaled) %*% X_scaled
eigen_A        <- eigen(A)
var_explained  <- eigen_A$values / sum(eigen_A$values)
var_cumulative <- cumsum(var_explained)

cat("\nVARIANCE EXPLAINED BY ECONOMIC COMPONENTS:\n")
for (i in seq_along(var_explained)) {
  cat(sprintf("PC%2d: %5.2f%%  (cumulative: %5.2f%%)\n", 
              i, var_explained[i] * 100, var_cumulative[i] * 100))
}

### SCREE PLOT ###
df_scree <- data.frame(PC = seq_along(var_explained), Individual = var_explained, Cumulative = var_cumulative)
p_scree <- ggplot(df_scree, aes(x = PC)) +
  geom_line(aes(y = Individual, color = "Individual")) +
  geom_point(aes(y = Individual)) +
  geom_line(aes(y = Cumulative, color = "Cumulative")) +
  labs(title = "Scree Plot: Economic Indicators", y = "Variance Proportion") + theme_minimal()

ggsave(file.path(PLOTS1_DIR, "scree_plot.png"), p_scree)

### 3D SCATTER PLOT ###
pca_res  <- prcomp(X_scaled, scale. = FALSE)
scores3d <- as.data.frame(pca_res$x[, 1:PCA_N_COMP])

# A cluster, a color for each income level
point_colors <- rainbow(length(unique(df_raw[[TARGET_COL]])))[df_raw[[TARGET_COL]]]

png(file.path(PLOTS1_DIR, "pca_3d.png"), width = 800, height = 700)
scatterplot3d::scatterplot3d(
  x = scores3d$PC1, y = scores3d$PC2, z = scores3d$PC3,
  xlab = "PC1 (Development)", ylab = "PC2 (Volatility)", zlab = "PC3",
  main = "3D PCA: Country Segmentation by Income Level",
  color = point_colors, pch = 19, angle = 35
)
dev.off()
