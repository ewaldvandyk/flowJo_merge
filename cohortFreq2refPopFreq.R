refPop <- "Single Cells"

cohorts_freq_xlsx <- "~/analysis/flowJoMerge/2021_03_30/all_cohorts_freq_2021_03_30.xlsx"
refTree_file <- "~/devel/R/flowJo_merge/refTrees/refTree_2021_02_22_NB_EVD.yml"

cohorts_baseFreq_xlsx <- "~/analysis/flow_interim/processed_data/all_cohorts_freqSC_2021_05_13.xlsx"


#Get current file location
srcFile <- NULL
stackPos <- 0
while (is.null(srcFile)) {
  stackPos <- stackPos-1
  srcFile <- sys.frame(stackPos)$srcfile  
}
flowJo_folder <- dirname(srcFile$filename)

#Source relevent functions
flowJoProc <- new.env()
freqProc <- new.env()
source(file.path(flowJo_folder, "flowJo_proc.R"), local = flowJoProc)
source(file.path(flowJo_folder, "freq_proc.R"), local = freqProc)

#Execute
freqDF <- read.xlsx(file = cohorts_freq_xlsx, sheetIndex = 1, 
                    as.data.frame = T, stringsAsFactors = F, check.names = F)

refTree <- flowJoProc$load_ref_tree(refYamlFile = refTree_file)
freqPerScDF <- freqProc$freqDF2relPopFreq(freqDF, refTree = refTree, relPop = refPop, flowJoProcEnv = flowJoProc)
freqPerScDF    <- freqProc$filterOnFlag(freqPerScDF, refTree, flagParam = "stimulated", valueKeep = F, naDefault = F, fieldPattern = "\\s*\\|\\s*Freq\\.\\s*of\\s*")
flowJoProc$df2xlsx(freqPerScDF, cohorts_baseFreq_xlsx)

