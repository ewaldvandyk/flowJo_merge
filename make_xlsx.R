#Input parameters
refTree_file <- "~/analysis/flowJoMerge/testing/2021_02_19/refTree_v0_3.yml" #Text file with reference tree and aliases

cohort_folder <- "~/data/Hannah/blood_flowJo/2021_02_16/BELLINI Trial/" # Data folder containing samples
output_xlsx <- "~/analysis/flowJoMerge/testing/2021_02_19/BELLINI.xlsx" #Output xlsx file with population frequency counts


#Data search parameters
file_pattern <- "FlowJo.*\\.xls$"
time_pattern <- "1\\s*([sS][tT][eE]|[dD][eE]|[sS][tT]|[nN][dD]|[rR][dD]|[tT][hH])?\\s*timepoint\\s*$"
# time_pattern <- NULL # Comment out if you want to use timepoint subfolders

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
refTree <- load_ref_tree(refYamlFile = refTree_file)
flowJoDFs <- cohortDir2dfList(cohortDir = cohort_folder, 
                              file_pattern = file_pattern, 
                              time_pattern = time_pattern)
dataMat <- gen_NA_matrix(df_list = flowJoDFs, refTree = refTree)
dataMat <- fill_matrix(flowJoDFs, refTree, dataMat)
dataDF <- dataMat2xlsx(dataMat, output_xlsx)