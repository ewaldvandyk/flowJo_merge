#Input parameters
ref_file <- "~/devel/R/flowJo_merge/output/ref_tree.yaml" #Text file with reference tree and aliases
data_folder <- "~/data/Noor/flowJow_2020_09_18/" # Data folder containing samples

output_xlsx <- "~/devel/R/flowJo_merge/output/freq_summary.xlsx" #Output xlsx file with population frequency counts

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
refTree <- load_ref_tree(refYamlFile = ref_file)
dataMat <- gen_NA_matrix(data_folder, refTree)
dataMat <- fill_matrix(data_folder, refTree, dataMat)
dataMat2xlsx(dataMat, output_xlsx)