library(readxl)
library(dplyr)
library(tidyverse)
library(caret)
library(randomForest)
library(scales)
library(stats)
library(stringr)
library(neuralnet)
library(ggplot2)

file_path <- "Baseball_player.xlsx"
batters <- read_xlsx(file_path, sheet = "Batter(2)")
pitchers <- read_xlsx(file_path, sheet = "Pitcher(2)")


############################################################
# Data Processing
############################################################

batters <- batters %>%
  mutate(
    `BB%`          = as.numeric(`BB%`),
    `K%`           = as.numeric(`K%`),
    WAR            = as.numeric(WAR),
    `wRC+`         = as.numeric(`wRC+`),
    HR             = as.numeric(HR),
    ISO            = as.numeric(ISO),
    Off            = as.numeric(Off),
    BsR            = as.numeric(BsR),
    age            = as.numeric(age),
    `service time` = as.numeric(`service time`)
  )

# clean `salary` string format
batters$salary <- gsub("\\$", "", batters$salary)
batters$salary <- gsub(",", "", batters$salary)
batters$salary <- trimws(batters$salary)
batters$salary <- as.numeric(batters$salary)


batters_model <- batters %>%
  filter(
    !is.na(salary), salary > 0,
    !is.na(WAR),
    !is.na(`wRC+`),
    !is.na(HR),
    !is.na(ISO),
    !is.na(`BB%`),
    !is.na(`K%`),
    !is.na(Off),
    !is.na(BsR),
    !is.na(age),
    !is.na(`service time`)
  ) %>%
  mutate(log_salary = log(salary))

cat("Batters in model:", nrow(batters_model), "\n")


intl_fa_batters <- c(
  "Shohei Ohtani",
  "Seiya Suzuki",
  "Jung Hoo Lee",
  "Masataka Yoshida",
  "Ha-Seong Kim"
)

batters_model <- batters_model %>%
  mutate(
    contract_type = case_when(
      Name %in% intl_fa_batters ~ "FA",
      `service time` < 3        ~ "PreArb",
      `service time` < 6        ~ "Arb",
      TRUE                      ~ "FA"
    )
  )

cat("Batters by contract type:\n")
print(table(batters_model$contract_type))

fa_batters  <- batters_model %>% filter(contract_type == "FA")
arb_batters <- batters_model %>% filter(contract_type == "Arb")


fa_perf <- fa_batters %>%
  select(
    `wRC+`,
    HR,
    ISO,
    `BB%`,
    `K%`,
    Off,
    BsR
  )

############################################################
# PCA
############################################################

fa_bat_pca <- prcomp(fa_perf, scale. = TRUE)

fa_batters$PC1 <- fa_bat_pca$x[, 1]
fa_batters$PC2 <- fa_bat_pca$x[, 2]


############################################################
# Linear Regression Model
############################################################
fa_bat_model <- lm(
  log_salary ~ PC1 + PC2 + WAR + age + `service time`,
  data = fa_batters
)

fa_batters$pred_log_salary <- predict(fa_bat_model)
fa_batters$pred_salary     <- exp(fa_batters$pred_log_salary)

fa_batters$Residual <- fa_batters$salary - fa_batters$pred_salary
fa_batters$Ratio    <- fa_batters$salary / fa_batters$pred_salary

fa_batters$Valuation_flag <- ifelse(
  fa_batters$Ratio > 1.2, "Overpaid",
  ifelse(fa_batters$Ratio < 0.8, "Underpaid", "Fairly Paid")
)



arb_perf <- arb_batters %>%
  select(
    `wRC+`,
    HR,
    ISO,
    `BB%`,
    `K%`,
    Off,
    BsR
  )

arb_bat_pca <- prcomp(arb_perf, scale. = TRUE)

arb_batters$PC1 <- arb_bat_pca$x[, 1]
arb_batters$PC2 <- arb_bat_pca$x[, 2]

arb_bat_model <- lm(
  log_salary ~ PC1 + PC2 + WAR + age + `service time`,
  data = arb_batters
)

arb_batters$pred_log_salary <- predict(arb_bat_model)
arb_batters$pred_salary     <- exp(arb_batters$pred_log_salary)

arb_batters$Residual <- arb_batters$salary - arb_batters$pred_salary
arb_batters$Ratio    <- arb_batters$salary / arb_batters$pred_salary

arb_batters$Valuation_flag <- ifelse(
  arb_batters$Ratio > 1.2, "Overpaid",
  ifelse(arb_batters$Ratio < 0.8, "Underpaid", "Fairly Paid")
)





pitchers <- pitchers %>%
  mutate(
    `K/9`         = as.numeric(`K/9`),
    `BB/9`        = as.numeric(`BB/9`),
    `HR/9`        = as.numeric(`HR/9`),
    `GB%`         = as.numeric(`GB%`),
    ERA           = as.numeric(ERA),
    FIP           = as.numeric(FIP),
    xFIP          = as.numeric(xFIP),
    WAR           = as.numeric(WAR),
    age           = as.numeric(age),
    `service time` = as.numeric(`service time`)
  )

pitchers$salary <- gsub("\\$", "", pitchers$salary)
pitchers$salary <- gsub(",", "", pitchers$salary)
pitchers$salary <- trimws(pitchers$salary)
pitchers$salary <- as.numeric(pitchers$salary)

pitchers_model <- pitchers %>%
  filter(
    !is.na(salary), salary > 0,
    !is.na(WAR),
    !is.na(`K/9`),
    !is.na(`BB/9`),
    !is.na(`HR/9`),
    !is.na(ERA),
    !is.na(FIP),
    !is.na(xFIP),
    !is.na(`GB%`),
    !is.na(age),
    !is.na(`service time`)
  ) %>%
  mutate(log_salary = log(salary))

cat("Pitchers in model:", nrow(pitchers_model), "\n")



npb_fa <- c(
  "Yoshinobu Yamamoto",
  "Shota Imanaga",
  "Kodai Senga",
  "Yuki Matsui"
)

pitchers_model <- pitchers_model %>%
  mutate(
    contract_type = case_when(
      Name %in% npb_fa      ~ "FA",
      `service time` < 3    ~ "PreArb",
      `service time` < 6    ~ "Arb",
      TRUE                  ~ "FA"
    )
  )

cat("Pitchers by contract type:\n")
print(table(pitchers_model$contract_type))

fa_pitchers  <- pitchers_model %>% filter(contract_type == "FA")
arb_pitchers <- pitchers_model %>% filter(contract_type == "Arb")

# FA Pitcher PCA + regression
fa_perf_p <- fa_pitchers %>%
  select(
    `K/9`,
    `BB/9`,
    `HR/9`,
    ERA,
    FIP,
    xFIP,
    `GB%`
  )

fa_pca <- prcomp(fa_perf_p, scale. = TRUE)

fa_pitchers$PC1 <- fa_pca$x[, 1]
fa_pitchers$PC2 <- fa_pca$x[, 2]

fa_model <- lm(
  log_salary ~ PC1 + PC2 + WAR + age + `service time`,
  data = fa_pitchers
)

fa_pitchers$pred_log_salary <- predict(fa_model)
fa_pitchers$pred_salary     <- exp(fa_pitchers$pred_log_salary)

fa_pitchers$Residual <- fa_pitchers$salary - fa_pitchers$pred_salary
fa_pitchers$Ratio    <- fa_pitchers$salary / fa_pitchers$pred_salary

fa_pitchers$Valuation_flag <- ifelse(
  fa_pitchers$Ratio > 1.2, "Overpaid",
  ifelse(fa_pitchers$Ratio < 0.8, "Underpaid", "Fairly Paid")
)

# Arb Pitcher PCA + Regression
arb_perf_p <- arb_pitchers %>%
  select(
    `K/9`,
    `BB/9`,
    `HR/9`,
    ERA,
    FIP,
    xFIP,
    `GB%`
  )

arb_pca <- prcomp(arb_perf_p, scale. = TRUE)

arb_pitchers$PC1 <- arb_pca$x[, 1]
arb_pitchers$PC2 <- arb_pca$x[, 2]

arb_model <- lm(
  log_salary ~ PC1 + PC2 + WAR + age + `service time`,
  data = arb_pitchers
)

arb_pitchers$pred_log_salary <- predict(arb_model)
arb_pitchers$pred_salary     <- exp(arb_pitchers$pred_log_salary)

arb_pitchers$Residual <- arb_pitchers$salary - arb_pitchers$pred_salary
arb_pitchers$Ratio    <- arb_pitchers$salary / arb_pitchers$pred_salary

arb_pitchers$Valuation_flag <- ifelse(
  arb_pitchers$Ratio > 1.2, "Overpaid",
  ifelse(arb_pitchers$Ratio < 0.8, "Underpaid", "Fairly Paid")
)



batters_flag  <- dplyr::bind_rows(fa_batters, arb_batters)
pitchers_flag <- dplyr::bind_rows(fa_pitchers, arb_pitchers)

# For all batters / pitchers：Create a binary (0/1) variable for whether a player is Overpaid or Underpaid.
batters_flag <- batters_flag %>%
  mutate(
    Overpaid_all  = ifelse(Valuation_flag == "Overpaid", 1, 0),
    Underpaid_all = ifelse(Valuation_flag == "Underpaid", 1, 0)
  )

pitchers_flag <- pitchers_flag %>%
  mutate(
    Overpaid_all  = ifelse(Valuation_flag == "Overpaid", 1, 0),
    Underpaid_all = ifelse(Valuation_flag == "Underpaid", 1, 0)
  )

## Arb: Top 10 Most Underpaid / Overpaid

arb_underpaid <- arb_pitchers %>%
  arrange(Ratio) %>%
  select(Name, Team, salary, pred_salary, Ratio,
         WAR, ERA, xERA, FIP, `K/9`, `BB/9`, Valuation_flag) %>%
  head(10)

arb_overpaid <- arb_pitchers %>%
  arrange(desc(Ratio)) %>%
  select(Name, Team, salary, pred_salary, Ratio,
         WAR, ERA, xERA, FIP, `K/9`, `BB/9`, Valuation_flag) %>%
  head(10)

arb_underpaid
arb_overpaid

############################################################
# Logistic Regression Model
############################################################

# Logistic Variable（Predictors）
bat_predictors <- c(
  "WAR", "wRC+", "HR", "ISO",
  "BB%", "K%", "Off", "BsR",
  "age", "service time"
)

pit_predictors <- c(
  "WAR", "K/9", "BB/9", "HR/9",
  "ERA", "FIP", "xFIP", "GB%",
  "age", "service time"
)



make_logit_formula <- function(y, predictors) {
  rhs <- paste(sprintf("`%s`", predictors), collapse = " + ")
  as.formula(paste(y, "~", rhs))
}

run_logit_and_top10 <- function(df, outcome_var, predictor_vars, group_label) {
  df_use <- df %>%
    dplyr::select(dplyr::all_of(c(outcome_var, predictor_vars))) %>%
    na.omit()
  
  df_use[[outcome_var]] <- as.numeric(df_use[[outcome_var]])
  
  form <- make_logit_formula(outcome_var, predictor_vars)
  
  model <- glm(
    formula = form,
    data    = df_use,
    family  = binomial
  )
  
  coef_mat   <- summary(model)$coefficients
  odds_ratio <- exp(coef(model))
  conf_int   <- suppressMessages(exp(confint(model)))
  
  or_table <- data.frame(
    Variable = names(odds_ratio),
    beta     = coef_mat[, "Estimate"],
    OR       = odds_ratio,
    CI_low   = conf_int[, 1],
    CI_high  = conf_int[, 2],
    p_value  = coef_mat[, "Pr(>|z|)"]
  )
  
  or_table_vars <- or_table[or_table$Variable != "(Intercept)", ]
  or_table_vars$effect_size <- abs(log(or_table_vars$OR))
  
  top_k <- min(10, nrow(or_table_vars))
  top10 <- or_table_vars %>%
    dplyr::arrange(dplyr::desc(effect_size)) %>%
    head(top_k)
  
  cat("\n=====================================\n")
  cat("Group:", group_label, "\n")
  cat("=====================================\n")
  print(top10)
}



run_logit_and_top10(
  df             = batters_flag,
  outcome_var    = "Overpaid_all",
  predictor_vars = bat_predictors,
  group_label    = "All Batters - Overpaid vs Others"
)


run_logit_and_top10(
  df             = batters_flag,
  outcome_var    = "Underpaid_all",
  predictor_vars = bat_predictors,
  group_label    = "All Batters - Underpaid vs Others"
)


run_logit_and_top10(
  df             = pitchers_flag,
  outcome_var    = "Overpaid_all",
  predictor_vars = pit_predictors,
  group_label    = "All Pitchers - Overpaid vs Others"
)


run_logit_and_top10(
  df             = pitchers_flag,
  outcome_var    = "Underpaid_all",
  predictor_vars = pit_predictors,
  group_label    = "All Pitchers - Underpaid vs Others"
)


fa_batters_flag <- fa_batters %>%
  mutate(
    Overpaid_FA  = ifelse(Valuation_flag == "Overpaid", 1, 0),
    Underpaid_FA = ifelse(Valuation_flag == "Underpaid", 1, 0)
  )

run_logit_and_top10(
  df             = fa_batters_flag,
  outcome_var    = "Overpaid_FA",
  predictor_vars = bat_predictors,
  group_label    = "FA Batters - Overpaid vs Others"
)


run_logit_and_top10(
  df             = fa_batters_flag,
  outcome_var    = "Underpaid_FA",
  predictor_vars = bat_predictors,
  group_label    = "FA Batters - Underpaid vs Others"
)


fa_pitchers_flag <- fa_pitchers %>%
  mutate(
    Overpaid_FA  = ifelse(Valuation_flag == "Overpaid", 1, 0),
    Underpaid_FA = ifelse(Valuation_flag == "Underpaid", 1, 0)
  )

run_logit_and_top10(
  df             = fa_pitchers_flag,
  outcome_var    = "Overpaid_FA",
  predictor_vars = pit_predictors,
  group_label    = "FA Pitchers - Overpaid vs Others"
)


run_logit_and_top10(
  df             = fa_pitchers_flag,
  outcome_var    = "Underpaid_FA",
  predictor_vars = pit_predictors,
  group_label    = "FA Pitchers - Underpaid vs Others"
)



############################################################
# Neural Network Model (Pitcher)
############################################################


core_predictors <- c("WAR", "age", "service_time")
performance_metrics <- c("FIP", "ERA", "BABIP", "K/9", "HR/9")


pitchers <- pitchers %>%
  filter(IP >= 10) %>%
  filter(!is.na(salary)) %>%
  mutate(LogSalary = log(salary))

dat <- pitchers 

key_model_vars <- c("LogSalary","salary", core_predictors, performance_metrics)
dat <- dat %>%
  mutate(service_time = as.character(`service time`)) %>%
  mutate(
    WAR = as.numeric(WAR),
    service_time = readr::parse_number(service_time)
  ) %>%
  drop_na(WAR, service_time) %>%
  drop_na(all_of(key_model_vars))


str(dat)

# Cluster
set.seed(123)
km <- kmeans(scale(dat[, c("WAR", "service_time")]), centers = 4, nstart = 25)
km

dat$Cluster <- factor(km$cluster)

plot(dat$service_time, dat$WAR,
     col = dat$Cluster, pch = 19,
     xlab = "Service Time (Years)",
     ylab = "WAR",
     main = "K-means Clustering by WAR & Service Time")
legend("topleft", legend = levels(dat$Cluster), col = 1:4, pch = 19)

# Split data into train and test dataset
set.seed(42) 

trainIndex <- createDataPartition(dat$LogSalary, p = 0.8, list = FALSE)
train_data <- dat[trainIndex, ]
test_data <- dat[-trainIndex, ]

cat("dataset has been splitted successfully：\n")
cat("training rows:", nrow(train_data), "\n")
cat("testing rows:", nrow(test_data), "\n")


clusters <- levels(train_data$Cluster)



# ------------- NN Models ----------------

TARGET_VAR <- "LogSalary" 
core_predictors <- c("WAR", "age", "service_time") 

performance_metrics <- c("FIP", "ERA", "BABIP", "K_per_9", "HR_per_9") 

# 1. Rename K/9, HR/9 columns of train_data and test_data
train_data <- train_data %>% 
  rename(K_per_9 = `K/9`, HR_per_9 = `HR/9`)
test_data <- test_data %>% 
  rename(K_per_9 = `K/9`, HR_per_9 = `HR/9`)

all_predictors <- c(core_predictors, performance_metrics)

predictor_vars <- all_predictors

# 2. Check all predictors are numeric values
for (col in c(TARGET_VAR, predictor_vars)) {
  if (!is.numeric(train_data[[col]])) {
    train_data[[col]] <- as.numeric(train_data[[col]])
    test_data[[col]] <- as.numeric(test_data[[col]])
  }
}


# --- 3. Create a pre-processing object (for Min-Max normalization of predictor variables only).
preproc_param <- preProcess(train_data[, predictor_vars], method = c("range"))

# --- 4. Apply Scaling ---
# Predictor variables are scaled
train_data_nn <- predict(preproc_param, train_data)
test_data_nn <- predict(preproc_param, test_data)

# --- 5. Scale LogSalary and Store Parameters ---
# 5a. Calculate Min/Max for LogSalary
min_logsalary <- min(train_data[[TARGET_VAR]], na.rm = TRUE)
max_logsalary <- max(train_data[[TARGET_VAR]], na.rm = TRUE)

# 5b. Apply Min-Max Scaling Formula
if ((max_logsalary - min_logsalary) > 0) {
  train_data_nn[[TARGET_VAR]] <- (train_data[[TARGET_VAR]] - min_logsalary) / (max_logsalary - min_logsalary)
  test_data_nn[[TARGET_VAR]] <- (test_data[[TARGET_VAR]] - min_logsalary) / (max_logsalary - min_logsalary)
  cat(paste0("LogSalary has beened scaled。Min: ", round(min_logsalary, 4), ", Max: ", round(max_logsalary, 4), "\n"))
} else {
  
  stop("Fatal Error Waring：LogSalary Max = Min。Please backtrack and re-partition the data.")
}

# 6. Building neural network models
nn_models <- list()
test_data$Predicted_LogSalary_NN_Scaled <- NA_real_

cat("\n Building neural network models ---\n")

for (k in clusters) {
  cluster_train_data_nn <- train_data_nn %>% 
    filter(Cluster == k) %>% 
    as.data.frame() 
  
  if(nrow(cluster_train_data_nn) < 10) {
    cat(paste0("Waring：Cluster ", k, " training samples are too small (<10)，Skip NN Modeling。\n"))
    next
  }
  
  # Building NN formula
  formula_nn <- as.formula(paste(TARGET_VAR, "~", paste(all_predictors, collapse = " + ")))
  cat(paste0("Cluster ", k, " try formula: ", as.character(formula_nn)[2], " ~ ", as.character(formula_nn)[3], "\n"))
  
  # Training
  tryCatch({
    model_nn <- neuralnet(
      formula_nn, 
      data = cluster_train_data_nn, 
      hidden = c(5, 4, 3),  
      linear.output = TRUE, 
      stepmax = 1e+06, 
      rep = 20 
    )
    nn_models[[paste0("Cluster_", k)]] <- model_nn
    
    # Testing (prediction)
    idx <- which(test_data_nn$Cluster == k)
    test_subset_nn <- test_data_nn[idx, ] %>% select(all_of(all_predictors)) %>% as.data.frame()
    nn_pred_scaled <- compute(model_nn, test_subset_nn)$net.result
    test_data[idx, "Predicted_LogSalary_NN_Scaled"] <- nn_pred_scaled
    
    cat(paste0("Clustering", k, " NN Model Traing and Testing completed。\n"))
    
  }, error = function(e) {
    cat(paste0("Training Failed！Clustering ", k, " Error Message: ", e$message, "\n"))
  })
}

# --- Evaluate and Reverse Transformation ---
test_data <- test_data %>%
  mutate(Predicted_LogSalary_NN = (Predicted_LogSalary_NN_Scaled * (max_logsalary - min_logsalary)) + min_logsalary)

test_data <- test_data %>%
  mutate(Predicted_Salary_NN = exp(Predicted_LogSalary_NN))

valid_predictions_nn <- test_data %>% drop_na(Predicted_Salary_NN) 
nn_rmse <- caret::RMSE(valid_predictions_nn$Predicted_Salary_NN, valid_predictions_nn$salary)

cat(paste0("\nNeural Network (NN) Overall RMSE: $", formatC(nn_rmse, format="f", digits=0, big.mark=","), "\n"))


# Evaluation

# --- --- Custom MAPE Function --- ---
# MAPE measures prediction error as a percentage of the actual value
mape <- function(actual, predicted) {
  mean(abs((actual - predicted) / actual), na.rm = TRUE) * 100
}


# Neural Network MAPE
nn_mape <- mape(test_data$salary, test_data$Predicted_Salary_NN)

cat("\n--- Model MAPE Calculation Results ---\n")

cat(paste0("NN Overall MAPE: ", round(nn_mape, 2), "%\n"))



# Plot Actual Values vs. Predicted Values for the Model (NN)
ggplot(test_data, aes(x = salary, y = Predicted_Salary_NN)) +
  geom_point(alpha = 0.6, color = "darkblue") + # Scatterplot
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red", size = 1) + # Ideal line y=x
  scale_x_continuous(labels = scales::dollar) + # X-axis formatted as dollar currency
  scale_y_continuous(labels = scales::dollar) + # Y-axis formatted as dollar currency
  labs(
    title = "Neural Network Model Prediction Accuracy (Actual Salary vs. Predicted Salary)",
    x = "Actual Salary ($)",
    y = "NN Predicted Salary ($)"
  ) +
  theme_minimal() +
  # Add text annotation for RMSE/MAPE
  annotate("text", x = max(test_data$salary, na.rm=TRUE) * 0.2, y = max(test_data$salary, na.rm=TRUE) * 0.9,
           label = paste("RMSE:", formatC(nn_rmse, format="f", digits=0, big.mark=","), "\nMAPE:", round(nn_mape, 2), "%"))




PRED_COL_NN <- "Predicted_Salary_NN" 

# --- 1. Calculate Percentage Residual (Percentage Residual) ---
test_data <- test_data %>%
  mutate(
    # Ensure salary is greater than 1
    Clean_Salary = ifelse(salary < 1000, 1000, salary),
    
    # Calculate percentage error: (Actual Salary - Predicted Salary) / Actual Salary * 100
    Residual_Percentage = ((Clean_Salary - !!sym(PRED_COL_NN)) / Clean_Salary) * 100,
    # Add absolute value column, used for sorting
    Abs_Residual_Percentage = abs(Residual_Percentage)
  )

# --- 2. Set Threshold and Filter ---
THRESHOLD <- 40
TOP_N <- 10

# Filter for players who were severely over- or underestimated, 
# and arrange in descending order by absolute value
anomalies_rf_extreme <- test_data %>%
  # Filter for records where the absolute residual percentage 
  # is greater than the threshold
  filter(Abs_Residual_Percentage > THRESHOLD) %>%
  arrange(desc(Abs_Residual_Percentage)) %>%
  #head(TOP_N) %>%
  select(PlayerId, Name, salary, !!sym(PRED_COL_NN), Residual_Percentage, Abs_Residual_Percentage, WAR, service_time, Cluster) 


cat(paste0("\n--- Most Extreme Anomalies in NN Model (Threshold: ", THRESHOLD, "%, Top ", TOP_N, " Players) ---\n"))
print(anomalies_rf_extreme)


############################################################
# Neural Network Model (Batter)
############################################################
core_predictors <- c("WAR", "age", "service_time")
performance_metrics <- c("wRC+", "RBI", "BABIP", "wOBA", "OBP", "PA")


batters <- batters %>%
  filter(PA >= 15) %>%
  filter(!is.na(salary)) %>%
  mutate(LogSalary = log(salary))

dat_2 <- batters 

key_model_vars <- c("LogSalary","salary", core_predictors, performance_metrics)
dat_2 <- dat_2 %>%
  mutate(service_time = as.character(`service time`)) %>%
  mutate(
    WAR = as.numeric(WAR),
    service_time = readr::parse_number(service_time)
  ) %>%
  drop_na(WAR, service_time) %>%
  drop_na(all_of(key_model_vars))


str(dat_2)

# Cluster
set.seed(123)
km <- kmeans(scale(dat_2[, c("WAR", "service_time")]), centers = 4, nstart = 25)
km

dat_2$Cluster <- factor(km$cluster)

plot(dat_2$service_time, dat_2$WAR,
     col = dat_2$Cluster, pch = 19,
     xlab = "Service Time (Years)",
     ylab = "WAR",
     main = "K-means Clustering by WAR & Service Time")
legend("topleft", legend = levels(dat_2$Cluster), col = 1:4, pch = 19)


# Split data into train and test datasets
set.seed(42) 

trainIndex <- createDataPartition(dat_2$LogSalary, p = 0.8, list = FALSE)
train_data <- dat_2[trainIndex, ]
test_data <- dat_2[-trainIndex, ]

cat("dataset has been splitted successfully：\n")
cat("training rows:", nrow(train_data), "\n")
cat("testing rows:", nrow(test_data), "\n")


clusters <- levels(train_data$Cluster)


# ------------- NN Models ----------------

TARGET_VAR <- "LogSalary" 

performance_metrics <- c("wRC_plus", "RBI", "BABIP", "wOBA", "OBP", "PA")
all_predictors <- c(core_predictors, performance_metrics)
# 1. Rename  wRC+ column of train_data and test_data
train_data <- train_data %>% 
  rename(wRC_plus = `wRC+`)
test_data <- test_data %>% 
  rename(wRC_plus = `wRC+`)

predictor_vars <- all_predictors

# 2. Check all predictors are numeric values
for (col in c(TARGET_VAR, predictor_vars)) {
  if (!is.numeric(train_data[[col]])) {
    train_data[[col]] <- as.numeric(train_data[[col]])
    test_data[[col]] <- as.numeric(test_data[[col]])
  }
}


# --- 3. Create a pre-processing object (for Min-Max normalization of predictor variables only).
preproc_param <- preProcess(train_data[, predictor_vars], method = c("range"))

# --- 4. Apply Scaling ---
# Predictor variables are scaled
train_data_nn <- predict(preproc_param, train_data)
test_data_nn <- predict(preproc_param, test_data)

# --- 5. Scale LogSalary and Store Parameters ---
# 5a. Calculate Min/Max for LogSalary
min_logsalary <- min(train_data[[TARGET_VAR]], na.rm = TRUE)
max_logsalary <- max(train_data[[TARGET_VAR]], na.rm = TRUE)

# 5b. Apply Min-Max Scaling Formula
if ((max_logsalary - min_logsalary) > 0) {
  train_data_nn[[TARGET_VAR]] <- (train_data[[TARGET_VAR]] - min_logsalary) / (max_logsalary - min_logsalary)
  test_data_nn[[TARGET_VAR]] <- (test_data[[TARGET_VAR]] - min_logsalary) / (max_logsalary - min_logsalary)
  cat(paste0("LogSalary has beened scaled。Min: ", round(min_logsalary, 4), ", Max: ", round(max_logsalary, 4), "\n"))
} else {
  
  stop("Fatal Error Waring：LogSalary Max = Min。Please backtrack and re-partition the data.")
}

# 6. Building neural network models
nn_models <- list()
test_data$Predicted_LogSalary_NN_Scaled <- NA_real_

cat("\n Building neural network models ---\n")

for (k in clusters) {
  cluster_train_data_nn <- train_data_nn %>% 
    filter(Cluster == k) %>% 
    as.data.frame() 
  
  if(nrow(cluster_train_data_nn) < 10) {
    cat(paste0("Waring：Cluster ", k, " training samples are too small (<10)，Skip NN Modeling。\n"))
    next
  }
  
  # Building NN formula
  formula_nn <- as.formula(paste(TARGET_VAR, "~", paste(all_predictors, collapse = " + ")))
  cat(paste0("Cluster ", k, " try formula: ", as.character(formula_nn)[2], " ~ ", as.character(formula_nn)[3], "\n"))
  
  # Training
  tryCatch({
    model_nn <- neuralnet(
      formula_nn, 
      data = cluster_train_data_nn, 
      hidden = c(5, 4, 3),  
      linear.output = TRUE, 
      stepmax = 1e+06, 
      rep = 20 
    )
    nn_models[[paste0("Cluster_", k)]] <- model_nn
    
    # Testing (prediction)
    idx <- which(test_data_nn$Cluster == k)
    test_subset_nn <- test_data_nn[idx, ] %>% select(all_of(all_predictors)) %>% as.data.frame()
    nn_pred_scaled <- compute(model_nn, test_subset_nn)$net.result
    test_data[idx, "Predicted_LogSalary_NN_Scaled"] <- nn_pred_scaled
    
    cat(paste0("Clustering", k, " NN Model Traing and Testing completed。\n"))
    
  }, error = function(e) {
    cat(paste0("Training Failed！Clustering ", k, " Error Message: ", e$message, "\n"))
  })
}

# --- Evaluate and Reverse Transformation ---
test_data <- test_data %>%
  mutate(Predicted_LogSalary_NN = (Predicted_LogSalary_NN_Scaled * (max_logsalary - min_logsalary)) + min_logsalary)

test_data <- test_data %>%
  mutate(Predicted_Salary_NN = exp(Predicted_LogSalary_NN))

valid_predictions_nn <- test_data %>% drop_na(Predicted_Salary_NN) 
nn_rmse <- caret::RMSE(valid_predictions_nn$Predicted_Salary_NN, valid_predictions_nn$salary)

cat(paste0("\nNeural Network (NN) Overall RMSE: $", formatC(nn_rmse, format="f", digits=0, big.mark=","), "\n"))


# Evaluation

# --- --- Custom MAPE Function --- ---
# MAPE measures prediction error as a percentage of the actual value
mape <- function(actual, predicted) {
  mean(abs((actual - predicted) / actual), na.rm = TRUE) * 100
}


# Neural Network 的 MAPE
nn_mape <- mape(test_data$salary, test_data$Predicted_Salary_NN)

cat("\n--- Model MAPE Calculation Results ---\n")

cat(paste0("NN Overall MAPE: ", round(nn_mape, 2), "%\n"))



# Plot Actual Values vs. Predicted Values for the Model (NN)
ggplot(test_data, aes(x = salary, y = Predicted_Salary_NN)) +
  geom_point(alpha = 0.6, color = "darkblue") + # Scatterplot
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red", size = 1) + # Ideal line y=x
  scale_x_continuous(labels = scales::dollar) + # X-axis formatted as dollar currency
  scale_y_continuous(labels = scales::dollar) + # Y-axis formatted as dollar currency
  labs(
    title = "Neural Network Model Prediction Accuracy (Actual Salary vs. Predicted Salary)",
    x = "Actual Salary ($)",
    y = "NN Predicted Salary ($)"
  ) +
  theme_minimal() +
  # Add text annotation for RMSE/MAPE
  annotate("text", x = max(test_data$salary, na.rm=TRUE) * 0.2, y = max(test_data$salary, na.rm=TRUE) * 0.9,
           label = paste("RMSE:", formatC(nn_rmse, format="f", digits=0, big.mark=","), "\nMAPE:", round(nn_mape, 2), "%"))




PRED_COL_NN <- "Predicted_Salary_NN" 

# --- 1. Calculate Percentage Residual (Percentage Residual) ---
test_data <- test_data %>%
  mutate(
    # Ensure salary is greater than 1
    Clean_Salary = ifelse(salary < 1000, 1000, salary),
    
    # Calculate percentage error: (Actual Salary - Predicted Salary) / Actual Salary * 100
    Residual_Percentage = ((Clean_Salary - !!sym(PRED_COL_NN)) / Clean_Salary) * 100,
    # Add absolute value column, used for sorting
    Abs_Residual_Percentage = abs(Residual_Percentage)
  )

# --- 2. Set Threshold and Filter ---
THRESHOLD <- 40
TOP_N <- 10

# Filter for players who were severely over- or underestimated, 
# and arrange in descending order by absolute value
anomalies_rf_extreme <- test_data %>%
  # Filter for records where the absolute residual percentage 
  # is greater than the threshold
  filter(Abs_Residual_Percentage > THRESHOLD) %>%
  arrange(desc(Abs_Residual_Percentage)) %>%
  #head(TOP_N) %>%
  select(PlayerId, Name, salary, !!sym(PRED_COL_NN), Residual_Percentage, Abs_Residual_Percentage, WAR, service_time, Cluster) 


cat(paste0("\n--- Most Extreme Anomalies in NN Model (Threshold: ", THRESHOLD, "%, Top ", TOP_N, " Players) ---\n"))
print(anomalies_rf_extreme)
