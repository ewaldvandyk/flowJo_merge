#Input parameters
flowJo_folder <- "~/devel/R/flowJo_merge/" # Directory in which this file is located
data_folder <- "~/data/Noor/flowJow_2020_09_18/" # Data folder containing samples
ref_file <- "~/devel/R/flowJo_merge/output/ref_tree.yaml" #Text file with reference tree and aliases
output_xlsx <- "~/devel/R/flowJo_merge/output/freq_summary.xlsx" #Output xlsx file with population frequency counts

#Execute
source(file.path(flowJo_folder, "flowJo_proc.R"))
refTree <- load_ref_tree(refYamlFile = ref_file)
dataMat <- gen_NA_matrix(data_folder, refTree)
dataMat <- fill_matrix(data_folder, refTree, dataMat)
dataMat2xlsx(dataMat, output_xlsx)