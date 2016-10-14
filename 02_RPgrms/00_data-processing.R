# Program: 00_data-processing-cm.R
# Purpose: Create crosswalk from ICD-9-CM to ICD-10-CM
# Author:  Max Rubinstein
# Date last modified: October 13, 2016

# Load libraries ----------------------------------------------------------------
library('purrr')
library('dplyr')
library('tidyr')
library('stringr')
source('02_RPgrms/helper-funs.R')

# Define data processing funs ---------------------------------------------------
read_data <- . %>%
  read.fwf(widths = c(6, 8, 5),
         header = FALSE,
         colClasses = rep('character', 3)) %>%
  set_names(c('icd_9', 'icd_10', 'combination')) %>%
  mutate(xwalk_flag = 'icd9to10') %>%
  dmap(trimws) 

stack_xwalk <- . %>%
  rbind(
    i10to9 %>%
      read.fwf(widths = c(8, 6, 5),
               header = F,
               colClasses = rep('character', 3)) %>%
      set_names(c('icd_10', 'icd_9', 'combination')) %>%
      mutate(xwalk_flag = 'icd10to9') %>%
      dmap(trimws)
  ) 

join_description <- . %>%
  left_join(
    i9names %>%
      readxl::read_excel() %>%
      set_names(c('icd_9', 'icd_9_descr', 'short_descr')) %>%
      select(-short_descr) %>%
      dmap(trimws), 
    by = 'icd_9'
  ) %>%
  left_join(
    i10names %>%
      read.fwf(widths = c(8, 200),
               header = FALSE,
               colClasses = rep('character', 2)) %>%
      set_names(c('icd_10', 'icd_10_descr')) %>%
      dmap(trimws),
    by = 'icd_10'
  )

process_data <- . %>%
  arrange(icd_9, icd_10) %>%
  order_cols(col_order) %>%
  mutate(duplicate_mapping = df_sub_dup(., c('icd_9', 'icd_10')))

# Execute all funs --------------------------------------------------------------
all_funs <- . %>%
  read_data() %>%
  stack_xwalk() %>%
  join_description() %>%
  process_data()

# Execute funs for CM codes -----------------------------------------------------
col_order <- '01_AnalyticFiles/varnames.yaml' %>% yaml_process()
i9to10    <- '00_RawData/2016_I9gem.txt'
i10to9    <- '00_RawData/2016_I10gem.txt'
i9names   <- '00_RawData/CMS32_DESC_LONG_SHORT_DX.xlsx'
i10names  <- '00_RawData/icd10cm_codes_2016.txt'

processed_data_cm  <- i9to10 %>% all_funs()

saveRDS(processed_data_cm, '01_AnalyticFiles/cm_mapping_2016.RDS')

# Execute funs for PCS codes -----------------------------------------------------
i9to10     <- '00_RawData/gem_i9pcs.txt'
i10to9     <- '00_RawData/gem_pcsi9.txt'
i9names    <- '00_RawData/CMS32_DESC_LONG_SHORT_SG.xlsx'
i10names   <- '00_RawData/icd10pcs_codes_2016.txt'

processed_data_pcs <- i9to10 %>% all_funs()

saveRDS(processed_data_pcs, '01_AnalyticFiles/pcs_mapping_2016.RDS')