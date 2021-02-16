#Input parameters
refTree_file <- "~/analysis/flowJoMerge/testing/2021_02_16/refTree_v2.yml" #Text file with reference tree and aliases

cohort_folder <- "~/data/Hannah/blood_flowJo/2021_02_16/Neo Adjuvant cohort/B16NBC/" # Data folder containing samples
output_xlsx <- "~/analysis/flowJoMerge/testing/2021_02_16/B16NBC.xlsx" #Output xlsx file with population frequency counts

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
flowJoDFs <- cohortDir2dfList(cohortDir = cohort_folder, file_pattern = "FlowJo")
dataMat <- gen_NA_matrix(df_list = flowJoDFs, refTree = refTree)
dataMat <- fill_matrix(flowJoDFs, refTree, dataMat)
dataDF <- dataMat2xlsx(dataMat, output_xlsx)