#Input parameters
input_refTree_file <- "~/analysis/flowJoMerge/testing/2021_02_17/refTree_v1.yml"
cohort_folder <- "~/data/Hannah/blood_flowJo/2021_02_16/Neo Adjuvant cohort/B16NBC/" # Data folder containing samples
output_refTree_file <- "~/analysis/flowJoMerge/testing/2021_02_17/refTree_v2.yml" 

#Data search parameters
file_pattern <- "FlowJo.*\\.xls$"
time_pattern <- "1\\s*([sS][tT][eE]|[dD][eE]|[sS][tT]|[nN][dD]|[rR][dD]|[tT][hH])?\\s*timepoint\\s*$"
time_pattern <- NULL

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