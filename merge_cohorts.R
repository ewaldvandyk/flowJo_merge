#Input parameters
cohort_names <- c("B16BHW", "BELLINI", "Triple_B", "Healthy")

cohort_file_list <- c("~/analysis/flowJoMerge/2021_01_31/rawXLSXs/B16BHW.xlsx",
                      "~/analysis/flowJoMerge/2021_01_31/rawXLSXs/BELLINI_Trial.xlsx", 
                      "~/analysis/flowJoMerge/2021_01_31/rawXLSXs/Triple_B.xlsx",
                      "~/analysis/flowJoMerge/2021_01_31/rawXLSXs/Healthy_controls.xlsx")

merged_out <- c("~/analysis/flowJoMerge/2021_01_31/rawXLSXs/all_cohorts.xlsx")

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