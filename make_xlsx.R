#Input parameters
refTree_file <- "~/data/Hannah/blood_flowJo/refTrees/ref_tree_NBC_2021_01_25_NB.yml" #Text file with reference tree and aliases

cohort_folder <- "/Volumes/Groups/GroupDeVisser/data/Hannah/Human blood/Triple B/" # Data folder containing samples
output_xlsx <- "~/analysis/flowJoMerge/2021_01_31/rawXLSXs/Triple_B.xlsx" #Output xlsx file with population frequency counts

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