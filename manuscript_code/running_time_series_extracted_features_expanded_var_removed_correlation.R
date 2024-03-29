# outer loop 

rm(list=ls()) #Clear all
cat("\014")

# set working directory: 
work_dir = 'U:/Hieu/CARDIA_longi_project'
# work_dir = '/Volumes/MR-Research$/Hieu/CARDIA_longi_project'

setwd(work_dir)

# if a package is not available, try:
# require(devtools)
# install_version("randomForestSRC", version = "3.0.1", repos = "http://cran.us.r-project.org")
library('randomForestSRC')
# load libraries:
list.of.packages <- c("mlbench",'ggplot2','caret', 'dplyr', 'tibble', 'ROCR','parallelMap'
                      ,'riskRegression', 'survival','randomForestSRC', 'survivalROC'
                      , 'pec', 'risksetROC','tsfeatures','survAUC')
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only = T)

ncores <- parallel::detectCores(all.tests = FALSE, logical = TRUE)

parallelMap::parallelStartSocket(ncores-1)


source_dir <- paste0(work_dir, '/code/git_code/snippet')
source(paste0(source_dir, '/running_rsf.R'))
source(paste0(source_dir, '/running_algo.R'))
source(paste0(source_dir, '/createDir.R'))
source(paste0(source_dir, '/subsetDataTopnVar.R'))
source(paste0(source_dir, '/classif_task.R'))
source(paste0(source_dir, '/predictSurvProb.R'))
source(paste0(source_dir, '/eval_performance.R'))
source(paste0(source_dir, '/eval_performance_using_different_auc_package.R'))
source(paste0(source_dir,'/normalize_var_importance.R'))




compute_performance_testset <- function(trained_model_, model_name_, test_data_, eval_times_, trained_data_){
  prob_risk_test <- predictRisk.rsf(trained_model_
                                    , newdata = test_data_
                                    , times = eval_times_
  )
  prob_risk_test_with_ID <- cbind(test_id, prob_risk_test)
  save(prob_risk_test_with_ID
       , file = paste0(saving.dir, '/prob_risk_test_set_with_ID_for_', model_name_, '.RData'))
  
  
  prob_risk_test[is.na(prob_risk_test)] = 0
  performance_testset = eval_performance3(prob.risk.test.set = prob_risk_test
                                          , test.data = test_data_
                                          , trained.data = trained_data_
                                          , eval.times = eval_times_
  )
  save(performance_testset
       , file = paste0(saving.dir, '/performance_testset_for_', model_name_, '.RData'))
  
  return(performance_testset)
}





# load extracted timeseries features:
loading_dir = paste0(work_dir, '/csv_files')

ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extracted_features_drop_nonunique_dropna_rm_nonrelevant_drop_correlated_dropna_2.csv'))
# 148 features
# 2_4 version


# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extract_relevant_drop_na_rm_corr_expanded_var_2.csv'))
# 148 features
# 2_5 version

# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extract_relevant_drop_na_2.csv'))

# 2_10 version
# best_model <- get(load(paste0(work_dir,"/rdata_files/rsf_expanded_var_and_ascvd_var_tsfeatures_plus_data_y15_fold_1/rsf_expanded_var_and_ascvd_var_tsfeatures_plus_data_y15.RData")))
# xvar <- best_model$xvar.names
# ts_features_full <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_drop_nonunique_dropna_2.csv'))
# # full features: 5827 features 
# # 2_10 version
# ts_features <- ts_features_full %>% dplyr::select(c('X',one_of(xvar)))




# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extract_relevant_drop_na_rm_corr_expanded_var_1.csv'))
# 150 features
# 2_8 version


# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_drop_nonunique_drop_na_relevant_df_drop_correlated.csv'))
# 125 features
# 2_7 version

# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extract_relevant_drop_na_rm_corr_expanded_var.csv'))
# 103 features
# 2_9 version





# tsfresh_features_extract_relevant_drop_na_2.csv

# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extracted_features_drop_nonunique_dropna_training_rm_nonrelevant_drop_correlated.csv')) 
# 2_6 version


# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extract_relevant_drop_na_rm_corr_expanded_var.csv'))
# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_drop_nonunique_dropna_rm_corr_expanded_var.csv'))
# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_extract_relevant_drop_na_expanded_var.csv'))
# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_drop_nonunique_dropna_drop_correlated_training_rm_nonrelevant.csv'))
# ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_drop_nonunique_drop_na_drop_correlated_expanded_var_crunhcr.csv'))

ts_features <- ts_features %>% dplyr::rename(ID = X)


# load the dataset
loading_dir = paste0(work_dir, '/csv_files')

data_longi_long_for_analysis <- read.csv(paste0(work_dir,'/csv_files/data_longi_long_format_expanded_variables_removed_missing_data_2.csv'))
data_longi_long_for_analysis$ID <- data_longi_long_for_analysis$ID %>% as.character()

subjects_in_cohort <- read.csv(paste0(work_dir,'/csv_files/subjects_in_final_analysis_cohort.csv'))






data_longi_long_up_to_y15 <- data_longi_long_for_analysis %>% filter(exam_year <=15)
data_longi_analysis_cohort <- data_longi_long_up_to_y15 %>% filter(ID %in% subjects_in_cohort[[1]])

# baseline data:
data_at_baseline <- data_longi_long_for_analysis %>% filter(!duplicated(ID, fromLast=FALSE)) 
# data_at_baseline <- data_longi_analysis_cohort %>% filter(ID %in% subjects_in_cohort[[1]]) %>% filter(exam_year == 0)
# most recent data at landmark time (y15):
data_y15 <- data_longi_analysis_cohort %>% filter(ID %in% subjects_in_cohort[[1]]) %>% 
  # filter(exam_year == 15)
  dplyr::filter(!duplicated(ID, fromLast=TRUE))

# truncate time to make start time at y15 (to avoid 15 years of immortal time):
data_y15_truncated_tte <- data_y15 %>% 
  mutate(time_te_in_yrs = time_te_in_yrs -15) %>% 
  dplyr::select(-time) %>% filter(time_te_in_yrs >0) %>%
  dplyr::rename(event = status) %>% dplyr::rename(time = time_te_in_yrs) %>%
  dplyr::select(-exam_year)



data <- data_y15_truncated_tte
# update age variable to be at landmark time:
data <- data %>% mutate(AGE_Y15 = AGE_Y0 +15) %>% dplyr::select(-AGE_Y0)





# load training IDs:
trainingid_all <- read.csv(paste0(work_dir,'/csv_files/all_training_set_ID_2.csv'))
validationid_all <- read.csv(paste0(work_dir,'/csv_files/all_validation_set_ID_2.csv'))
testingid_all <- read.csv(paste0(work_dir,'/csv_files/all_testing_set_ID_2.csv'))




### START BUILDING MODELS: #################################################################




seed <- 4495
set.seed(seed)
nfolds <- 10

endpt <- 17; # after Year 15
eval_times <- seq(1, endpt, by = 1)

data$ID <- data$ID %>% as.character()
ts_features$ID <- as.character(ts_features$ID)


# merge y15 data with ts derived features:

# data_tsfeatures <- data %>% dplyr::select('ID','event','time','AGE_Y15','MALE','RACEBLACK') %>%
#   inner_join(ts_features, by = 'ID')

# data_tsfeatures_disjoint <- data %>% dplyr::select('ID','event','time','AGE_Y15','MALE','RACEBLACK') %>%
#   anti_join(ts_features, by = 'ID')
# data_tsfeatures_disjoint %>% nrow()


# data <- data_tsfeatures[complete.cases(data_tsfeatures),]
# check if nrow of data is the same as cohort population


# for (fold in 1:nfolds){
#   # Training and fitting model:
#   # fold = 1
#   trainingid <- na.omit(c(trainingid_all[,fold], validationid_all[,fold]))
#   train_data <- data %>% filter(ID %in% trainingid)
#   test_data <- data %>% filter((ID %in% testingid_all[,fold]))
#   train_id <- train_data$ID
#   test_id <- test_data$ID
#   train_data$ID <- NULL
#   test_data$ID <- NULL
# 
# 
#   model_name <- 'rsf_expanded_var_tsfeatures_corr_rm'
#   gc()
#   main_dir <- paste0(work_dir, '/rdata_files')
#   sub_dir <- paste0(model_name, '_fold_',fold)
# 
#   if(!dir.exists(file.path(main_dir, sub_dir))){
#     createDir(main_dir, sub_dir)
#   }
#   #set.seed(seed)
#   model <- running_rsf(train_data)
#   saving_dir <- file.path(main_dir, sub_dir)
#   save(model, file = paste0(saving_dir,'/', model_name, '.RData'))
# 
# 
# 
#   # Test set performance: ###################################################################
#   loading.dir <- paste0(work_dir, '/rdata_files/', model_name, '_fold_', fold)
#   saving.dir <- loading.dir
#   trained_data <- train_data
#   trained_model <- model
# 
#   tryCatch({
# 
#     # probability of having had the disease:
#     prob_risk_test <- predictRisk.rsf(trained_model
#                                       , newdata = test_data
#                                       , times = eval_times
#     )
#     prob_risk_test_with_ID <- cbind(test_id, prob_risk_test)
#     save(prob_risk_test_with_ID
#          , file = paste0(saving.dir, '/prob_risk_test_set_with_ID.RData'))
# 
# 
# 
#     prob_risk_test[is.na(prob_risk_test)] = 0
#     performance_testset = eval_performance3(prob.risk.test.set = prob_risk_test
#                                             , test.data = test_data
#                                             , trained.data = trained_data
#                                             , eval.times = eval_times
#     )
#     save(performance_testset
#          , file = paste0(saving.dir, '/performance_testset.RData'))
# 
# 
# 
#     prob_risk_train <- predictRisk.rsf(trained_model
#                                        , newdata = trained_data
#                                        , times = eval_times
#     )
#     prob_risk_train_with_ID <- cbind(train_id, prob_risk_train)
#     save(prob_risk_train_with_ID
#          , file = paste0(saving.dir, '/prob_risk_train_set_with_ID.RData'))
# 
#   }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
# 
# 
#   ## VIMP:
#   max.subtree = max.subtree(model, conservative = F)
#   #save(max.subtree, file = paste(saving.dir, '/RF_maxtree.Rdata', sep = ''))
# 
#   # Get minimal depth of maximal subtree in terms of variable name, ascending order:
#   allvardepth = sort(max.subtree$order[, 1])
#   allvardepth.df = data.frame(Variable=names(allvardepth),MinDepthMaxSubtree=allvardepth,row.names = NULL)
# 
#   allvardepth.df$normalized_depth = normalize_var_imp(allvardepth.df$MinDepthMaxSubtree)
# 
#   write.csv(allvardepth.df, file = paste(saving_dir, '/depth_rank.csv', sep = ''),row.names=F)
# 
# }












data_tsfeatures_plus_most_recent_by_y15 <- data_y15_truncated_tte %>% 
  mutate(AGE_Y15 = AGE_Y0 +15) %>% dplyr::select(-AGE_Y0) %>% 
  left_join(ts_features, by = 'ID') %>%
  dplyr::select('ID','event','time',everything())

data <- data_tsfeatures_plus_most_recent_by_y15[complete.cases(data_tsfeatures_plus_most_recent_by_y15),]
# check nrow(data)



# perf_best <- get(load(paste0(work_dir, '/rdata_files','/cForest_expanded_var_tsfeatures_plus_data_y15_rm_correlation_2_fold_1/performance_testset.RData')))
# # 0.851 iAUC
# perf_best_rsf_run2 <- get(load(paste0(work_dir, '/rdata_files','/rsf_expanded_var_and_ascvd_var_tsfeatures_plus_data_y15_2_fold_1/performance_testset.RData')))
# # 0.849 iAUC
# 
# perf_best_rsf <- get(load(paste0(work_dir, '/rdata_files','/rsf_expanded_var_and_ascvd_var_tsfeatures_plus_data_y15_fold_1/performance_testset.RData')))
# # 0.86 iAUC
# per_rsf_y15 <- get(load(paste0(work_dir, '/rdata_files','/rsf_expanded_var_data_y15_test_fold_1/performance_testset.RData')))
# # 0.828



# for (fold in 1:nfolds){
#   ## fold = 1
#   # Training and fitting model:
#   trainingid <- na.omit(c(trainingid_all[,fold], validationid_all[,fold]))
#   train_data <- data %>% filter(ID %in% trainingid)
#   test_data <- data %>% filter((ID %in% testingid_all[,fold]))
#   train_id <- train_data$ID
#   test_id <- test_data$ID
#   train_data$ID <- NULL
#   test_data$ID <- NULL
# 
# 
#   model_name <- 'rsf_expanded_var_tsfeatures_plus_data_y15_2_4'
#   
#   gc()
#   main_dir <- paste0(work_dir, '/rdata_files')
#   sub_dir <- paste0(model_name, '_fold_',fold)
# 
#   if(!dir.exists(file.path(main_dir, sub_dir))){
#     createDir(main_dir, sub_dir)
#   }
#   
#   
#   
#   # set.seed(seed)
#   # model_all_var <- running_rsf(train_data)
# 
# 
# 
#   corr_matrix = cor(train_data)
#   corr_matrix_fillna = corr_matrix
#   corr_matrix_fillna[is.na(corr_matrix)] <-0
#   # 
#   # hc = findCorrelation(corr_matrix_fillna, cutoff=0.5) # putt any value as a "cutoff" 
#   # hc = sort(hc)
#   # reduced_train_data = train_data[,-c(hc)] 
#   # reduced_train_data$event = train_data$event
#   # reduced_train_data$time = train_data$time
#   
#   ratio = 0.1 # 1/10: 0.826 AUC lower seems worse iAUC
#   corr_matrix_correlated_with_event = data.frame(corr_matrix_fillna)['event'] %>% 
#     tibble::rownames_to_column("var_name") %>%  
#     mutate(abs_val = abs(event)) %>%
#     arrange(desc(abs_val)) %>% dplyr::slice(1:round(ratio*ncol(train_data))) 
# 
#   reduced_var <- corr_matrix_correlated_with_event$var_name
#   
#   
#   set.seed(seed)
#   model_reduced_var <- running_rsf(train_data %>% dplyr::select(one_of(c('event', 'time', reduced_var))))
#   # perf_reduced_var$iauc.uno
#   # 0.826
#   
#   set.seed(seed) # 0.836 iAUC
#   var_select <- var.select(object = model_reduced_var, conservative = 'high', refit = FALSE)
#   #  model_reduced_var_varselect <- var_select$rfsrc.refit.obj
#   set.seed(seed)
#   model_reduced_var_varselect <- running_rsf(train_data %>% dplyr::select(one_of(c('event', 'time', var_select$topvars))))
# 
#   
#   
#   saving_dir <- file.path(main_dir, sub_dir)
#   # save(model, file = paste0(saving_dir,'/', model_name, 'unfiltered_untuned.RData'))
#   save(model_reduced_var, file = paste0(saving_dir,'/', 'model_reduced_var.RData'))
#   save(model_reduced_var_varselect, file = paste0(saving_dir,'/', 'model_reduced_var_varselect.RData'))
#   
# 
# 
# 
#   # Test set performance: ###################################################################
#   loading.dir <- paste0(work_dir, '/rdata_files/', model_name, '_fold_', fold)
#   saving.dir <- loading.dir
#   trained_data <- train_data
#   # trained_model <- model
#   
#   
#   
#   
# 
# #  tryCatch({
#     
#   
#     perf_reduced_var <- compute_performance_testset(model_reduced_var, 'model_reduced_var', test_data, eval_times, trained_data = train_data)
#     print(perf_reduced_var$iauc.uno)
#     perf_refit_var <- compute_performance_testset(model_reduced_var_varselect, 'model_reduced_var_varselect', test_data, eval_times, trained_data = train_data)
#     print(perf_refit_var$iauc.uno)
#     cat("\n")
#     
#     
# #  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
# }










## MERGE WITH OLD ASCVD VAR EXTRACTED FEATURES: ############





new_data <- data
# load extracted timeseries features:
loading_dir = paste0(work_dir, '/csv_files')
old_ts_features <- read.csv(paste0(work_dir,'/csv_files/tsfresh_features_drop_nonunique_drop_na_relevant_df_drop_correlated.csv'))
old_ts_features <- old_ts_features %>% dplyr::rename(ID = X)



data_ts_ascvd_var <- old_ts_features

data_ts_ascvd_var$ID <- as.character(data_ts_ascvd_var$ID)

`%notin%` <- Negate(`%in%`)
data_ts_ascvd_var_non_overlap <- data_ts_ascvd_var[,names(data_ts_ascvd_var)[names(data_ts_ascvd_var) %notin% names(new_data)]]
data_ts_ascvd_var_non_overlap_with_ID <- cbind (ID = data_ts_ascvd_var$ID, data_ts_ascvd_var_non_overlap)

merged_data <- new_data %>% inner_join(data_ts_ascvd_var_non_overlap_with_ID, by = 'ID')

# nrow(merged_data)

data <- merged_data

for (fold in 1:nfolds){

  ## fold = 1
  trainingid <- na.omit(c(trainingid_all[,fold], validationid_all[,fold]))
  train_data <- data %>% filter(ID %in% trainingid)
  test_data <- data %>% filter((ID %in% testingid_all[,fold]))
  train_id <- train_data$ID
  test_id <- test_data$ID
  train_data$ID <- NULL
  test_data$ID <- NULL


  model_name <- 'rsf_expanded_var_and_ascvd_var_tsfeatures_plus_data_y15_2_4'
  gc()
  main_dir <- paste0(work_dir, '/rdata_files')
  sub_dir <- paste0(model_name, '_fold_',fold)

  if(!dir.exists(file.path(main_dir, sub_dir))){
    createDir(main_dir, sub_dir)
  }
  
  set.seed(seed)
  # model <- running_rsf(train_data)
  model <- rfsrc(Surv(time,event)~., data = train_data 
            , ntree = 1001
            , splitrule = 'logrank' #there is also logrankrandom, logrankscore, and conserve splitting  
  )
  
  # set.seed(seed)
  # var_select <- var.select(object = model, conservative = 'low', refit = FALSE)
  # 
  # set.seed(seed)
  # refit_model <- running_rsf(train_data %>% dplyr::select(one_of(c('event', 'time', var_select$topvars))))
  
  # set.seed(seed) 
  # model_tuning <- running_rsf_tuned(train_data)
  # 
  # 
  # 
  saving_dir <- file.path(main_dir, sub_dir)
  save(model, file = paste0(saving_dir,'/','unfiltered_untuned.RData'))
  #save(refit_model, file = paste0(saving_dir,'/', model_name, 'filtered_untuned.RData'))
  # 
  #save(model_tuning, file = paste0(saving_dir,'/tuned_model.RData'))



  # Test set performance: ###################################################################
  loading.dir <- paste0(work_dir, '/rdata_files/', model_name, '_fold_', fold)
  saving.dir <- loading.dir
  trained_data <- train_data
  trained_model <- model
  # trained_model <- get(load(paste0(loading.dir, '/', model_name, 'unfiltered_untuned.RData')))


  
  
#  refit_perf <- compute_performance_testset(refit_model, 'rsf_var_select', test_data, eval_times,train_data) 
  
  tryCatch({

    # probability of having had the disease:
    prob_risk_test <- predictRisk.rsf(trained_model
                                      , newdata = test_data
                                      , times = eval_times
    )
    prob_risk_test_with_ID <- cbind(test_id, prob_risk_test)
    save(prob_risk_test_with_ID
         , file = paste0(saving.dir, '/prob_risk_test_set_with_ID.RData'))



    prob_risk_test[is.na(prob_risk_test)] = 0
    performance_testset = eval_performance3(prob.risk.test.set = prob_risk_test
                                            , test.data = test_data
                                            , trained.data = trained_data
                                            , eval.times = eval_times
    )
    print(performance_testset$iauc.uno)
    save(performance_testset
         , file = paste0(saving.dir, '/performance_testset.RData'))



    # prob_risk_train <- predictRisk.rsf(trained_model
    #                                    , newdata = trained_data
    #                                    , times = eval_times
    # )
    # prob_risk_train_with_ID <- cbind(train_id, prob_risk_train)
    # save(prob_risk_train_with_ID
    #      , file = paste0(saving.dir, '/prob_risk_train_set_with_ID.RData'))

  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})

  
  # # VIMP:
  # 
  # 
  # max.subtree = max.subtree(model, conservative = F)
  # #save(max.subtree, file = paste(saving.dir, '/RF_maxtree.Rdata', sep = ''))
  # 
  # # Get minimal depth of maximal subtree in terms of variable name, ascending order:
  # allvardepth = sort(max.subtree$order[, 1])
  # allvardepth.df = data.frame(Variable=names(allvardepth),MinDepthMaxSubtree=allvardepth,row.names = NULL)
  # 
  # allvardepth.df$normalized_depth = normalize_var_imp(allvardepth.df$MinDepthMaxSubtree)
  # 
  # write.csv(allvardepth.df, file = paste(saving_dir, '/depth_rank.csv', sep = ''),row.names=F)
  
  
}






# 
# 
# 
# data <- merged_data
# 
# for (fold in 1:nfolds){
#   ## fold = 1 
#   # # Training and fitting model:
#   # trainingid <- na.omit(c(trainingid_all[,fold], validationid_all[,fold]))
#   # train_data <- data %>% filter(ID %in% trainingid)
#   # test_data <- data %>% filter((ID %in% testingid_all[,fold]))
#   # train_id <- train_data$ID
#   # test_id <- test_data$ID
#   # train_data$ID <- NULL
#   # test_data$ID <- NULL
#   # 
#   # 
#   # model_name <- 'rsf_expanded_var_and_ascvd_var_tsfeatures_plus_data_y15_2_1'
#   # gc()
#   # main_dir <- paste0(work_dir, '/rdata_files')
#   # sub_dir <- paste0(model_name, '_fold_',fold)
#   # 
#   # if(!dir.exists(file.path(main_dir, sub_dir))){
#   #   createDir(main_dir, sub_dir)
#   # }
#   # #set.seed(seed)
#   # model <- running_rsf(train_data)
#   # saving_dir <- file.path(main_dir, sub_dir)
#   # save(model, file = paste0(saving_dir,'/', model_name, '.RData'))
#   # 
#   # 
#   # 
#   # # Test set performance: ###################################################################
#   # loading.dir <- paste0(work_dir, '/rdata_files/', model_name, '_fold_', fold)
#   # saving.dir <- loading.dir
#   # trained_data <- train_data
#   # trained_model <- model
#   # 
#   # tryCatch({
#   # 
#   #   # probability of having had the disease:
#   #   prob_risk_test <- predictRisk.rsf(trained_model
#   #                                     , newdata = test_data
#   #                                     , times = eval_times
#   #   )
#   #   prob_risk_test_with_ID <- cbind(test_id, prob_risk_test)
#   #   save(prob_risk_test_with_ID
#   #        , file = paste0(saving.dir, '/prob_risk_test_set_with_ID.RData'))
#   # 
#   # 
#   # 
#   #   prob_risk_test[is.na(prob_risk_test)] = 0
#   #   performance_testset = eval_performance3(prob.risk.test.set = prob_risk_test
#   #                                           , test.data = test_data
#   #                                           , trained.data = trained_data
#   #                                           , eval.times = eval_times
#   #   )
#   #   save(performance_testset
#   #        , file = paste0(saving.dir, '/performance_testset.RData'))
#   # 
#   # 
#   # 
#   #   prob_risk_train <- predictRisk.rsf(trained_model
#   #                                      , newdata = trained_data
#   #                                      , times = eval_times
#   #   )
#   #   prob_risk_train_with_ID <- cbind(train_id, prob_risk_train)
#   #   save(prob_risk_train_with_ID
#   #        , file = paste0(saving.dir, '/prob_risk_train_set_with_ID.RData'))
#   # 
#   # }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
#   # 
#   # 
#   # # VIMP:
#   # 
#   # 
#   # max.subtree = max.subtree(model, conservative = F)
#   # #save(max.subtree, file = paste(saving.dir, '/RF_maxtree.Rdata', sep = ''))
#   # 
#   # # Get minimal depth of maximal subtree in terms of variable name, ascending order:
#   # allvardepth = sort(max.subtree$order[, 1])
#   # allvardepth.df = data.frame(Variable=names(allvardepth),MinDepthMaxSubtree=allvardepth,row.names = NULL)
#   # 
#   # allvardepth.df$normalized_depth = normalize_var_imp(allvardepth.df$MinDepthMaxSubtree)
#   # 
#   # write.csv(allvardepth.df, file = paste(saving_dir, '/depth_rank.csv', sep = ''),row.names=F)
#   # 
#   
#   ## fold = 1
#   trainingid <- na.omit(c(trainingid_all[,fold], validationid_all[,fold]))
#   train_data <- data %>% filter(ID %in% trainingid)
#   test_data <- data %>% filter((ID %in% testingid_all[,fold]))
#   train_id <- train_data$ID
#   test_id <- test_data$ID
#   train_data$ID <- NULL
#   test_data$ID <- NULL
#   
#   
#   model_name <- 'rsf_expanded_var_and_ascvd_var_tsfeatures_plus_data_y15_2_5'
#   gc()
#   main_dir <- paste0(work_dir, '/rdata_files')
#   sub_dir <- paste0(model_name, '_fold_',fold)
#   
#   if(!dir.exists(file.path(main_dir, sub_dir))){
#     createDir(main_dir, sub_dir)
#   }
#   set.seed(seed)
#   model <- running_rsf(train_data)
#   
#   # var_select <- var.select(object = model, conservative = 'medium', refit = FALSE)
#   # 
#   # refit_model <- running_rsf(train_data %>% dplyr::select(one_of(c('event', 'time', var_select$topvars))))
#   # 
#   # model_tuning <- running_rsf_tuned(train_data %>% dplyr::select(one_of(c('event', 'time', var_select$topvars))))
#   # 
#   # 
#   # 
#   # saving_dir <- file.path(main_dir, sub_dir)
#   # save(model, file = paste0(saving_dir,'/', model_name, 'unfiltered_untuned.RData'))
#   # save(refit_model, file = paste0(saving_dir,'/', model_name, 'filtered_untuned.RData'))
#   # 
#   # save(model_tuning, file = paste0(saving_dir,'/', model_name, '.RData'))
#   
#   
#   
#   # Test set performance: ###################################################################
#   loading.dir <- paste0(work_dir, '/rdata_files/', model_name, '_fold_', fold)
#   saving.dir <- loading.dir
#   trained_data <- train_data
#   #trained_model <- model_tuning
#   # trained_model <- get(load(paste0(loading.dir, '/', model_name, '.RData')))
#   trained_model <- model
#   
#   
#   
#   #  refit_perf <- compute_performance_testset(refit_model, 'rsf_var_select', test_data, eval_times,train_data) 
#   
#   tryCatch({
#     
#     # probability of having had the disease:
#     prob_risk_test <- predictRisk.rsf(trained_model
#                                       , newdata = test_data
#                                       , times = eval_times
#     )
#     prob_risk_test_with_ID <- cbind(test_id, prob_risk_test)
#     save(prob_risk_test_with_ID
#          , file = paste0(saving.dir, '/prob_risk_test_set_with_ID.RData'))
#     
#     
#     
#     prob_risk_test[is.na(prob_risk_test)] = 0
#     performance_testset = eval_performance3(prob.risk.test.set = prob_risk_test
#                                             , test.data = test_data
#                                             , trained.data = trained_data
#                                             , eval.times = eval_times
#     )
#     save(performance_testset
#          , file = paste0(saving.dir, '/performance_testset.RData'))
#     
#     
#     
#     # prob_risk_train <- predictRisk.rsf(trained_model
#     #                                    , newdata = trained_data
#     #                                    , times = eval_times
#     # )
#     # prob_risk_train_with_ID <- cbind(train_id, prob_risk_train)
#     # save(prob_risk_train_with_ID
#     #      , file = paste0(saving.dir, '/prob_risk_train_set_with_ID.RData'))
#     
#   }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
#   
#   
#   # # VIMP:
#   # 
#   # 
#   # max.subtree = max.subtree(model, conservative = F)
#   # #save(max.subtree, file = paste(saving.dir, '/RF_maxtree.Rdata', sep = ''))
#   # 
#   # # Get minimal depth of maximal subtree in terms of variable name, ascending order:
#   # allvardepth = sort(max.subtree$order[, 1])
#   # allvardepth.df = data.frame(Variable=names(allvardepth),MinDepthMaxSubtree=allvardepth,row.names = NULL)
#   # 
#   # allvardepth.df$normalized_depth = normalize_var_imp(allvardepth.df$MinDepthMaxSubtree)
#   # 
#   # write.csv(allvardepth.df, file = paste(saving_dir, '/depth_rank.csv', sep = ''),row.names=F)
#   
#   
# }
# 
