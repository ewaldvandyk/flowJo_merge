#Generate a new reference tree for gating strategy for a fixed cohort

#Input parameters
cohort_folder <- "/Volumes/Groups/GroupDeVisser/data/Hannah/Human blood/BELLINI" # Data folder containing samples
output_refTree_file <- "~/devel/R/flowJo_merge/output/2021_10_15/ref_tree_v1.yaml" #Text file with reference tree and aliases

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
flowJoDFs <- cohortDir2dfList(cohortDir = cohort_folder, 
                              file_pattern  = file_pattern, 
                              time_pattern = time_pattern)
refTree <- dfList2Tree(flowJoDFs)
tree2yamlFile(refTree, refYamlFile = output_refTree_file)
print(refTree)