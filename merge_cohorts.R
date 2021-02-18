#Input parameters
cohort_names <- c("B16BHW", "B16NBC","TripleB", "BELLINI", "Healthy")

cohort_file_list <- c("~/analysis/flowJoMerge/2021_02_18/B16BHW.xlsx",
                      "~/analysis/flowJoMerge/2021_02_18/B16NBC.xlsx", 
                      "~/analysis/flowJoMerge/2021_02_18/TripleB.xlsx",
                      "~/analysis/flowJoMerge/2021_02_18/BELLINI.xlsx",
                      "~/analysis/flowJoMerge/2021_02_18/Healthy.xlsx")

merged_out <- "~/analysis/flowJoMerge/2021_02_18/all_cohorts_2021_02_18.xlsx"

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