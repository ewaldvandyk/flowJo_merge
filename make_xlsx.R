#Input parameters
refTree_file <- "~/data/Hannah/blood_flowJo/refTrees/ref_tree_NBC_2021_01_25_NB.yml" #Text file with reference tree and aliases

cohort_folder <- "~/data/Hannah/blood_flowJo/2021_01_21/B16BHW/" # Data folder containing samples
output_xlsx <- "~/analysis/flowJoMerge/testing/2021_02_01/B16BHW.xlsx" #Output xlsx file with population frequency counts

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