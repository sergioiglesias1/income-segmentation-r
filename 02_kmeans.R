# K-MEANS
source("config.R")
load("C:/Users/Usuario/Downloads/repo_R/data/.workspace.RData")

library(ggplot2)
library(factoextra)
library(reshape2)

if (!dir.exists(PLOTS2_DIR)) dir.create(PLOTS2_DIR, recursive = T)

### K-ELBOW METHOD ###

p_elbow <- fviz_nbclust(X_scaled, kmeans, method = "wss") +
  geom_vline(xintercept = KMEANS_K, linetype = 2) +
  labs(title = "Optimal Clusters for World Economies")

ggsave(file.path(PLOTS2_DIR, "elbow_method.png"), p_elbow)

### K-MEANS CLUSTERING ###

set.seed(KMEANS_SEED)
res_kmeans <- kmeans(X_scaled, centers = KMEANS_K, nstart = KMEANS_NSTART)

# Saving clusters into the original df
df_raw$cluster_id <- res_kmeans$cluster

### Cluster Visualization (PCA + K-Means) ###

p_cluster <- fviz_cluster(res_kmeans, data = X_scaled,
                          geom = "point", ellipse.type = "norm",
                          ggtheme = theme_minimal(),
                          main = "Economic Clusters (K-Means)")

ggsave(file.path(PLOTS2_DIR, "kmeans_clusters.png"), p_cluster)

### CENTROIDS ###

centroids <- aggregate(X, by = list(Cluster = res_kmeans$cluster), FUN = mean)
cat("\nCENTROIDES POR CLUSTER (Promedios económicos):\n")
print(centroids)

### Boxplot (GDPpc by Cluster) ###

p_box <- ggplot(df_raw, aes(x = factor(cluster_id), y = gdp_per_capita, fill = factor(cluster_id))) +
  geom_boxplot() +
  labs(title = "GDP per Capita Distribution by Cluster", x = "Cluster", y = "GDP per Capita") +
  theme_classic()

ggsave(file.path(PLOTS2_DIR, "boxplot_gdp.png"), p_box)

###  Cluster vs Real Income Level ###
# Table with real income levels and assigned clusters
eval_table <- table(Real_Income = df_raw$income, Cluster = res_kmeans$cluster)
cat("\nCROSS-TABULATION: Real Income Level vs Clusters:\n")
print(eval_table)

# Heatmap for cross-tabulation
eval_df <- as.data.frame(eval_table)
p_eval <- ggplot(eval_df, aes(x = Cluster, y = Real_Income, fill = Freq)) +
  geom_tile() +
  geom_text(aes(label = Freq), color = "white") +
  scale_fill_gradient(low = "gray", high = "darkblue") +
  labs(title = "Cluster Purity: How well K-Means found Income Groups") +
  theme_minimal()

ggsave(file.path(PLOTS2_DIR, "purity_heatmap.png"), p_eval)

cat("\nAnalysis complete. Results saved in visualization folders.\n")
