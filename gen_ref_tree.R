#Input parameters
ref_data_folder <- "~/data/Noor/flowJow_2020_09_18/" # Data folder containing samples

output_ref_file <- "~/devel/R/flowJo_merge/output/ref_tree.yaml" #Text file with reference tree and aliases

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
refTree <- make_ref_tree(ref_data_folder, refYamlFile = output_ref_file, filePattern = "FlowJo")
print(refTree)