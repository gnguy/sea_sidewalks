#' Given a data.table of data (and estimates if desired), calculate summary metrics of the outcome_var across id_vars
#'
#' Can produce the following metrics: mean, median, upper, lower, min, max, 
#' count (of total observations, non-NA observations, and NA observations)
#' std_dev (standard deviation), variance, 
#' med_ad_med (median absolute deviation from the median), mean_ad_med (mean absolute deviation from the median), 
#' med_ad_mean (median absolute deviation from the mean), mean_ad_mean (mean absolute deviation from the mean),
#' mapd (mean absolute percentage deviation), mean_ar (mean absolute residual), med_ar (median absolute residual)
#' mean_apr (mean absolute percentage residual), med_apr (median absolute percentage residual)
#'
#' @param data data.table containing id_vars and outcome_var
#' @param id_vars character vector of id variables (e.g. c("ihme_loc_id", "sex", "year", "sim"))
#' @param outcome_var character, variable name of outcome variable (e.g. "mean")
#' @param metrics character vector of metrics to produce:
#'      mean
#'      median
#'      lower: The .025th quantile
#'      upper: The .975th quantile
#'      min
#'      max
#'      count: Total number of rows within the unique combination of id variables
#'      count_no_na: Total number of non-NA rows within the unique combination of id variables
#'      count_na: Total number of NA rows within the unique combination of id variables
#'      std_dev: Calculated using the base sd function
#'      variance: Calculated using the base variance function
#'      med_ad_med: Median absolute deviation = median(|outcome_var - median(outcome_var)|)
#'      mean_ad_med: Mean absolute deviation = mean(|outcome_var - median(outcome_var)|)
#'      med_ad_mean: Median absolute deviation = median(|outcome_var - mean(outcome_var)|)
#'      mean_ad_mean: Mean absolute deviation = mean(|outcome_var - mean(outcome_var)|)
#'      mean_apd: Mean absolute percentage deviation = 100 * mean(|(outcome_var - mean(outcome_var))/mean(outcome_var)|)
#'      mean_ar: Mean absolute residual = mean(|outcome_var_data - outcome_var_estimates|). Note: requires estimates data.table
#'      med_ar: Median absolute residual = median(|outcome_var_data - outcome_var_estimates|). Note: requires estimates data.table
#'      mean_apr: Mean absolute percentage residual = mean(|(outcome_var_data - outcome_var_estimates) / outcome_var_estimates|). Note: requires estimates data.table
#'      med_apr: Median absolute percentage residual = median(|(outcome_var_data - outcome_var_estimates) / outcome_var_estimates|). Note: requires estimates data.table
#' @param na.rm logical, whether to remove NA values when calculating the metrics above (EXCEPT for count, which counts total rows regardless of value). Default: F
#' @param copy_dt logical, whether to copy the data.table to avoid modify-on-reference issues. Set to F to avoid copying input data.tables. Default: T
#' @param estimates data.table containing id_vars and outcome_var. 
#'        Optional -- if not specified, summary metrics such as median absolute residual will be NA
#' @param estimate_id_vars character vector of id variables that UNIQUELY identify estimates data (can't have duplicates to avoid a m:m merge)
#'        Used to merge with data data.table, all variables must exist in estimates and data data.tables
#'
#' @return data.table collapsed down to unique observations by id_var, with columns for each specified metric
#' @import data.table
#' @import assertthat
#' @export
#'
#' @examples
#' library(data.table)
#' test <- data.table(x = c(205:214), y = c(1:5, 1:2, 1:3))
#' summarize_data(test, id_vars = "y", outcome_var = "x", metrics = c("mean","median", "med_ad_med", "mean_ad_med", "count"))
#' test[y == 1 & x == 205, x := NA]
#' summarize_data(test, id_vars = "y", outcome_var = "x", metrics = c("mean","median", "med_ad_med", "mean_ad_med", "count"))
#' summarize_data(test, id_vars = "y", outcome_var = "x", metrics = c("mean","median", "med_ad_med", "mean_ad_med", "count", "count_no_na", "count_na"), na.rm = T)
#' summarize_data(test, id_vars = "y", outcome_var = "x", metrics = c("mean", "median", "mean_ar", "med_ar", "mean_apr", "med_apr"), na.rm = T, estimates = test_estimates, estimate_id_vars = "y")

summarize_data <- function(data, id_vars, outcome_var, metrics, na.rm = F, copy_dt = T,
                           estimates=NULL, estimate_id_vars = NULL) {
  
  ## Assertions: data, id_vars, outcome_var, and metrics are not NA and valid values
    assertthat::assert_that(is.data.table(data))
    assertthat::assert_that(is.string(id_vars[1]))
    assertthat::assert_that(is.string(outcome_var))
    assertthat::assert_that(is.string(metrics[1]))
    assertthat::assert_that(is.logical(na.rm))
    assertthat::assert_that(is.logical(copy_dt))
    assertthat::assert_that(is.data.table(estimates) | is.null(estimates))
    assertthat::assert_that(is.string(estimate_id_vars[1]) | is.null(estimate_id_vars))

    for(var in id_vars) {
        if(!var %in% colnames(data)) stop(paste0(var, " does not exist in data data.table"))
    }

    for(var in c(outcome_var, estimate_id_vars)) {
        if(!var %in% colnames(data)) stop(paste0(var, " does not exist in data data.table"))
        if(!is.null(estimates)) {
            if(!var %in% colnames(estimates)) stop(paste0(var, " does not exist in estimates data.table"))
        }
    }

    metric_list <- c("mean", "median", "lower", "upper", "min", "max", "count", "count_no_na", "count_na",
                     "med_ad_med", "mean_ad_med", "med_ad_mean",
                     "mean_ad_mean", "std_dev", "variance", "mean_apd", 
                     "mean_ar", "med_ar", "mean_apr", "med_apr")
    for(met in metrics) {
        if(!met %in% metric_list) stop(paste0(met, " is not a valid metric. Valid metrics are: ", paste(metric_list, collapse = " ")))
    }

    if(is.null(estimates) & ("mean_ar" %in% metrics | "med_ar" %in% metrics | "mean_apr" %in% metrics | "med_apr" %in% metrics)) {
        stop("Need estimates data.table in order to calculate mean or median absolute residual (mean_ar or med_ar)")
    }

  ## Set keys on the data and format/merge data appropriately
    if(copy_dt == T) working_data <- copy(data)
    if(copy_dt == F) working_data <- data
    setnames(working_data, outcome_var, "outcome_var")

    if(!is.null(estimates) & ("mean_ar" %in% metrics | "med_ar" %in% metrics | "mean_apr" %in% metrics | "med_apr" %in% metrics)) {
      if(copy_dt == T) working_estimates <- copy(estimates)
      if(copy_dt == F) working_estimates <- estimates

      ## Check that dt is unique by estimate_id_vars
      setkeyv(working_estimates, estimate_id_vars)
      unique_dt_obs <- nrow(unique(working_estimates[, by = estimate_id_vars]))
      if(unique_dt_obs != nrow(working_estimates)) stop(paste0("Data are not unique by estimate_id_vars: ", paste(estimate_id_vars, collapse = " ")))

      setnames(working_estimates, outcome_var, "outcome_var_estimates")
      working_estimates <- working_estimates[, .SD, .SDcols = c(estimate_id_vars, "outcome_var_estimates")]
      working_data <- merge(working_data, working_estimates, all.x = T, by = estimate_id_vars)
      miss_rows <- nrow(working_data[is.na(outcome_var_estimates)])
      if(miss_rows != 0) warning(paste0(miss_rows, " rows of data did not have corresponding estimate values after merging on estimates data.table using estimate_id_vars"))
    }

    setkeyv(working_data, id_vars)

  ## Initialize string for the data.table calculations
    out_list <- paste0("list(")
    add_string <- function(x) paste0(out_list, x, ", ")

  ## Define functions
    if("mean" %in% metrics) out_list <- add_string(paste0("mean = mean(outcome_var, na.rm = ", na.rm, ")"))
    if("median" %in% metrics) out_list <- add_string(paste0("median = as.double(median(outcome_var, na.rm = ", na.rm, "))"))
    if("lower" %in% metrics) out_list <- add_string(paste0("lower = quantile(outcome_var, probs = .025, na.rm = ", na.rm, ")"))
    if("upper" %in% metrics) out_list <- add_string(paste0("upper = quantile(outcome_var, probs = .975, na.rm = ", na.rm, ")"))
    if("min" %in% metrics) out_list <- add_string(paste0("min = min(outcome_var, na.rm = ", na.rm, ")"))
    if("max" %in% metrics) out_list <- add_string(paste0("max = max(outcome_var, na.rm = ", na.rm, ")"))
    if("count" %in% metrics) out_list <- add_string(paste0("count = length(outcome_var)"))
    if("count_no_na" %in% metrics) out_list <- add_string(paste0("count_no_na = length(outcome_var[!is.na(outcome_var)])"))
    if("count_na" %in% metrics) out_list <- add_string(paste0("count_na = length(outcome_var[is.na(outcome_var)])"))
    if("std_dev" %in% metrics) out_list <- add_string(paste0("std_dev = sd(outcome_var, na.rm = ", na.rm, ")"))
    if("variance" %in% metrics) out_list <- add_string(paste0("variance = var(outcome_var, na.rm = ", na.rm, ")"))
    if("med_ad_med" %in% metrics) out_list <- add_string(paste0("med_ad_med = as.double(median(abs(outcome_var - median(outcome_var, na.rm = ", na.rm, ")), na.rm = ", na.rm, "))"))
    if("mean_ad_med" %in% metrics) out_list <- add_string(paste0("mean_ad_med = mean(abs(outcome_var - median(outcome_var, na.rm = ", na.rm, ")), na.rm = ", na.rm, ")"))
    if("med_ad_mean" %in% metrics) out_list <- add_string(paste0("med_ad_mean = as.double(median(abs(outcome_var - mean(outcome_var, na.rm = ", na.rm, ")), na.rm = ", na.rm, "))"))
    if("mean_ad_mean" %in% metrics) out_list <- add_string(paste0("mean_ad_mean = mean(abs(outcome_var - mean(outcome_var, na.rm = ", na.rm, ")), na.rm = ", na.rm, ")"))
    if("mean_apd" %in% metrics) out_list <- add_string(paste0("mean_apd = mean(abs((outcome_var - mean(outcome_var, na.rm = ", na.rm, 
                                                              ")) / mean(outcome_var, na.rm = ", na.rm, 
                                                              ")), na.rm = ", na.rm, ")"))
    if("mean_ar" %in% metrics) out_list <- add_string(paste0("mean_ar = mean(abs(outcome_var - outcome_var_estimates), na.rm = ", na.rm, ")"))
    if("med_ar" %in% metrics) out_list <- add_string(paste0("med_ar = as.double(median(abs(outcome_var - outcome_var_estimates), na.rm = ", na.rm, "))"))
    if("mean_apr" %in% metrics) out_list <- add_string(paste0("mean_apr = 100 * mean(abs((outcome_var - outcome_var_estimates) / outcome_var_estimates), na.rm = ", na.rm, ")"))
    if("med_apr" %in% metrics) out_list <- add_string(paste0("med_apr = 100 * as.double(median(abs((outcome_var - outcome_var_estimates) / outcome_var_estimates), na.rm = ", na.rm, "))"))

  ## Format the output by removing the last comma and space, and then adding the closing parenthesis
    out_list <- substr(out_list, 1, nchar(out_list) - 2)
    out_list <- paste0(out_list, ")")
    # print(out_list)

  ## Format and output dataset
    out_dt <- working_data[, eval(parse(text = out_list)), by = id_vars]
    return(out_dt)
}

