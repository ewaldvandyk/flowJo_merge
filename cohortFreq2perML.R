cohorts_freq_xlsx <- "~/analysis/flowJoMerge/2021_02_25/all_cohorts_2021_02_25.xlsx"
cohorts_perML_xlsx <- "~/analysis/flowJoMerge/2021_02_25/all_cohorts_perML_2021_02_25.xlsx"

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
popMains <- freqProc$freqDF2relPopFreq(freqDF, relPop = "Single Cells")