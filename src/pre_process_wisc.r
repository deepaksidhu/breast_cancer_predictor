# author: Tiffany Timbers
# date: 2019-12-18

"Cleans, splits and pre-processes (scales) the Wisconsin breast cancer data (from http://mlr.cs.umass.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.data).
Writes the training and test data to separate feather files.

Usage: src/pre_process_wisc.r --input=<input> --out_dir=<out_dir>
  
Options:
--input=<input>       Path (including filename) to raw data (feather file)
--out_dir=<out_dir>   Path to directory where the processed data should be written
" -> doc

library(feather)
library(tidyverse)
library(caret)
library(docopt)
set.seed(2020)

opt <- docopt(doc)
main <- function(input, out_dir){
  # read data and convert class to factor
  raw_data <- read_feather(input) 
  colnames(raw_data) <- c("id",
                         "class",
                         "mean_radius",
                         "mean_texture",
                         "mean_perimeter", 
                         "mean_area",
                         "mean_smoothness",
                         "mean_compactness",
                         "mean_concavity",
                         "mean_concave_points",
                         "mean_symmetry",
                         "mean_fractal_dimension",
                         "se_radius",
                         "se_texture",
                         "se_perimeter", 
                         "se_area",
                         "se_smoothness",
                         "se_compactness",
                         "se_concavity",
                         "se_concave_points",
                         "se_symmetry",
                         "se_fractal_dimension",
                         "max_radius",
                         "max_texture",
                         "max_perimeter", 
                         "max_area",
                         "max_smoothness",
                         "max_compactness",
                         "max_concavity",
                         "max_concave_points",
                         "max_symmetry",
                         "max_fractal_dimension")
  raw_data <- raw_data %>% 
    select(-id) %>% 
    mutate(class = as.factor(class))
  
  # split into training and test data sets
  training_rows <- raw_data %>% 
    select(class) %>% 
    pull() %>%
    createDataPartition(p = 0.75, list = FALSE)
  training_data <- raw_data %>% slice(training_rows)
  test_data <- raw_data %>% slice(-training_rows)
  
  # scale test data using scale factor
  x_train <- training_data %>% 
    select(-class) 
  x_test <- test_data %>% 
    select(-class)
  pre_process_scaler <- preProcess(x_train, method = c("center", "scale"))
  x_train_scaled <- predict(pre_process_scaler, x_train)
  x_test_scaled <- predict(pre_process_scaler, x_test)
  training_scaled <- x_train_scaled %>% 
    mutate(class = training_data %>% select(class) %>% pull())
  test_scaled <- x_test_scaled %>% 
    mutate(class = test_data %>% select(class) %>% pull())
  
  # write scale factor to a file
  try({
    dir.create(out_dir)
  })
  saveRDS(pre_process_scaler, file = paste0(out_dir, "/scale_factor.rds"))
  
  # write training and test data to feather files
  write_feather(training_scaled, paste0(out_dir, "/training.feather"))
  write_feather(test_scaled, paste0(out_dir, "/test.feather"))
}

main(opt[["--input"]], opt[["--out_dir"]])