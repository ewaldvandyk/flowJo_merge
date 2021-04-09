cohorts_freq_xlsx <- "~/analysis/flowJoMerge/2021_03_30/all_cohorts_freq_2021_03_30.xlsx"
cohorts_cellPerML_xlsx <- "~/data/Hannah/blood_flowJo/2021_04_07/all_cohorts_totalCountsPerMl_NB.xlsx"

refTree_file <- "~/devel/R/flowJo_merge/refTrees/refTree_2021_02_22_NB_EVD.yml"
cohorts_perML_xlsx <- "~/analysis/flow_interim/processed_data/all_cohorts_perML_2021_04_08_v2.xlsx"

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
cellPerMlDF <- read.xlsx(file = cohorts_cellPerML_xlsx, sheetIndex = 1,
                         as.data.frame = T, stringsAsFactors = F, check.names = F)

refTree <- flowJoProc$load_ref_tree(refYamlFile = refTree_file)
freqPerScDF <- freqProc$freqDF2relPopFreq(freqDF, refTree = refTree, relPop = "Single Cells", flowJoProcEnv = flowJoProc)
cPerMlDF    <- freqProc$freq2cPerMl(freqPerScDF, cellPerMlDF)
cPerMlDF    <- freqProc$filterOnFlag(cPerMlDF, refTree, flagParam = "stimulated", valueKeep = F, naDefault = F, fieldPattern = "\\s*\\|\\s*Count\\s*")
flowJoProc$df2xlsx(cPerMlDF, cohorts_perML_xlsx)

