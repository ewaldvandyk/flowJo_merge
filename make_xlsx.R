#Input parameters
refTree_file <- "~/analysis/flowJoMerge/testing/2021_02_02/refTree_v4.yml" #Text file with reference tree and aliases

cohort_folder <- "~/data/Hannah/blood_flowJo/2021_01_21/Healthy controls/" # Data folder containing samples
output_xlsx <- "~/analysis/flowJoMerge/testing/2021_02_02/Healthy.xlsx" #Output xlsx file with population frequency counts

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
dataMat <- gen_NA_matrix(cohort_folder, refTree)
dataMat <- fill_matrix(cohort_folder, refTree, dataMat)
dataDF <- dataMat2xlsx(dataMat, output_xlsx)