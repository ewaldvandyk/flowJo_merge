#Input parameters
flowJo_folder <- "~/devel/R/flowJo_merge/" # Directory in which this file is located
ref_data_folder <- "~/data/Noor/flowJow_2020_09_18/" # Data folder containing samples
output_ref_file <- "~/devel/R/flowJo_merge/output/ref_tree.yaml" #Text file with reference tree and aliases

#Execute
source(file.path(flowJo_folder, "flowJo_proc.R"))
refTree <- make_ref_tree(ref_data_folder, refYamlFile = output_ref_file, filePattern = "FlowJo")
print(refTree)