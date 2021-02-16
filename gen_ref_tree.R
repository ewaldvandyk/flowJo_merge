#Input parameters
cohort_folder <- "~/data/Hannah/blood_flowJo/2021_02_16/Neo Adjuvant cohort/B16BHW/" # Data folder containing samples

output_refTree_file <- "~/analysis/flowJoMerge/testing/2021_02_16/refTree_v1.yml" #Text file with reference tree and aliases

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
flowJoDFs <- cohortDir2dfList(cohortDir = cohort_folder, file_pattern = "FlowJo")
refTree <- dfList2Tree(flowJoDFs)
tree2yamlFile(refTree, refYamlFile = output_refTree_file)
print(refTree)