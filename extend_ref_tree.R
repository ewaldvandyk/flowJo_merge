#Input parameters
input_refTree_file <- "~/devel/R/flowJo_merge/refTrees/refTree_2021_02_22_NB_EVD.yml"
cohort_folder <- "/Volumes/Groups/GroupDeVisser/data/Hannah/Human blood/BELLINI" 
output_refTree_file <- "~/devel/R/flowJo_merge/refTrees/refTree_2021_10_15_EVD.yml" 

#Data search parameters
file_pattern <- "FlowJo.*\\.xls$"
time_pattern <- "[^.]?1\\s*([sS][tT][eE]|[dD][eE]|[sS][tT]|[nN][dD]|[rR][dD]|[tT][hH])?\\s*timepoint\\s*$"
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
input_refTree <- load_ref_tree(refYamlFile = input_refTree_file)
flowJoDFs <- cohortDir2dfList(cohortDir = cohort_folder, 
                              file_pattern  = file_pattern, 
                              time_pattern = time_pattern)
output_refTree <- add_chains_2_ref_tree(inputTree = input_refTree, df_list = flowJoDFs)
refTree <- tree2yamlFile(tree = output_refTree, refYamlFile = output_refTree_file)
print(refTree)