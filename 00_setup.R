gc()

source("config.R")

required_packages <- c("dplyr", "psych", "moments", "factoextra",
                       "scatterplot3d", "ggplot2", "pROC", "reshape2", "WDI")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = T)) install.packages(pkg)
  library(pkg, character.only = T)
}

# Data loading
cat("Loading data from World Bank API...")

# WDI indicators to use (2022)
indicators <- c(
  "gdp_per_capita" = "NY.GDP.PCAP.PP.CD",
  "internet_users" = "IT.NET.USER.ZS",
  "mobile_subs"    = "IT.CEL.SETS.P2",
  "life_expectancy"= "SP.DYN.LE00.IN",
  "inflation"      = "FP.CPI.TOTL.ZG"
)

df_raw <- WDI(indicator = indicators, country = "all", start = 2022, end = 2022, extra = T)

# Simple data cleaning
df_raw <- df_raw[df_raw$region != "Aggregates", ]
df_raw <- na.omit(df_raw)

# Encoding target variable
df_raw[[TARGET_COL]] <- as.numeric(as.factor(df_raw$income))

cat("Dataset loaded:", nrow(df_raw), "countries,", ncol(df_raw), "variables\n")

# We select only the numeric indicators we downloaded
X <- df_raw %>% select(all_of(names(indicators)))

# Descriptive statistics
print(summary(X))

S <- var(X)
R <- cor(X)

# KMO and Bartlett's test for dataset adequacy
bartlett_p <- psych::cortest.bartlett(cor(X), n = nrow(X))$p.value
kmo_val    <- psych::KMO(X)$MSA

cat("\nBartlett test p-value:", bartlett_p, "\n")
cat("KMO (MSA):", round(kmo_val, 4), "\n")

# Data standardization for PCA
X_scaled <- scale(X)

# Save R workspace
save(df_raw, X, X_scaled, R, S, file = "data/.workspace.RData")
cat("\nWorkspace saved to data/.workspace.RData\n")
