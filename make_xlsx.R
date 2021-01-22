#Input parameters
refTree_file <- "~/data/Hannah/blood_flowJo/2021_01_21/ref_tree_NBC_2021_01_22_v2.yml" #Text file with reference tree and aliases
cohort_folder <- "~/data/Hannah/blood_flowJo/2021_01_21/Triple B/" # Data folder containing samples

output_xlsx <- "~/data/Hannah/blood_flowJo/2021_01_21/freqSummary_TripleB.xlsx" #Output xlsx file with population frequency counts

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
dataMat2xlsx(dataMat, output_xlsx)