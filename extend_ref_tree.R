#Input parameters
input_refTree_file <- "~/data/Hannah/blood_flowJo/2021_01_21/ref_tree_NBC_2021_01_22.yml"
cohort_folder <- "~/data/Hannah/blood_flowJo/2021_01_21/B16NBC/" # Data folder containing samples
output_refTree_file <- "~/data/Hannah/blood_flowJo/2021_01_21/ref_tree_NBC_2021_01_22_v2.yml" 

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
output_refTree <- add_chains_2_ref_tree(inputTree = input_refTree, dataDir = cohort_folder, filePattern = "FlowJo")
refTree <- tree2yamlFile(tree = output_refTree, refYamlFile = output_refTree_file)
print(refTree)