#Input parameters
cohort_names <- c("B16BHW", "B16NBC","TNBC", "BELLINI", "Healthy")

cohort_file_list <- c("~/analysis/flowJoMerge/2021_03_30/B16BHW.xlsx",
                      "~/analysis/flowJoMerge/2021_03_30/B16NBC.xlsx", 
                      "~/analysis/flowJoMerge/2021_03_30/TNBC.xlsx",
                      "~/analysis/flowJoMerge/2021_03_30/BELLINI.xlsx",
                      "~/analysis/flowJoMerge/2021_03_30/Healthy.xlsx")

merged_out <- "~/analysis/flowJoMerge/2021_03_30/all_cohorts_freq_2021_03_30.xlsx"

#Get current file location
srcFile <- NULL
stackPos <- 0
while (is.null(srcFile)) {
  stackPos <- stackPos-1
  srcFile <- sys.frame(stackPos)$srcfile  
}
flowJo_folder <- dirname(srcFile$filename)

#Execute
source(file.path(flowJo_folder, "flowJo_proc.R"))


cohort_dfs <- xlsxFileList2df_list(cohort_file_list)
cohort_df <- merge_cohorts(cohort_names, cohort_dfs)
df2xlsx(df = cohort_df, xlsxFile = merged_out)