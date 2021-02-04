#Input parameters
cohort_folder <- "~/data/Hannah/blood_flowJo/2021_01_21/B16BHW/" # Data folder containing samples

output_refTree_file <- "~/analysis/flowJoMerge/testing/2021_02_02/refTree_v3.yml" #Text file with reference tree and aliases

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
refTree <- make_ref_tree(cohort_folder, filePattern = "FlowJo")
tree2yamlFile(refTree, refYamlFile = output_refTree_file)
print(refTree)