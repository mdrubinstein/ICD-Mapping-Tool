order_cols <- function(df, col_names) {
  df[, col_names]
}

df_sub_dup <- function(df, col_names) {
  df[, col_names] %>%
  duplicated()
}

yaml_process <- function(file) {
  file %>%
    yaml::yaml.load_file() %>%
    str_split(' ') %>%
    unlist() 
}