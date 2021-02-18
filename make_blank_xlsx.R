#Input parameters
cohort_names <- c("TripleB", "Bellini", "Healthy", "B16BHW", "B16NBC")

cohort_dir_list <- c("~/data/Hannah/blood_flowJo/2021_02_16/Triple B/",
                     "~/data/Hannah/blood_flowJo/2021_02_16/BELLINI Trial/", 
                     "~/data/Hannah/blood_flowJo/2021_02_16/Healthy controls/",
                     "~/data/Hannah/blood_flowJo/2021_02_16/Neo Adjuvant cohort/B16BHW/",
                     "~/data/Hannah/blood_flowJo/2021_02_16/Neo Adjuvant cohort/B16NBC/")

merged_out <- "~/analysis/flowJoMerge/2021_02_17/cohort_sample_template_2021_02_17.xlsx"

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

df <- merge_blank_cohorts(cohort_names = cohort_names, cohort_dirs = cohort_dir_list)
df2xlsx(df = df, xlsxFile = merged_out)