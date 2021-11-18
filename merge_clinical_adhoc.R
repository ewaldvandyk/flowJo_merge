clinFile <- "~/data/Hannah/blood_flowJo/2021_03_25/all_cohorts_clinical_2021_11_17_EVD.xlsx"
# dataFile <- "~/analysis/flow_interim/processed_data/all_cohorts_perML_2021_04_08_v2.xlsx"
# fullFile <- "~/analysis/flow_interim/processed_data/all_cohorts_clin_perML_2021_11_17.xlsx"
dataFile <- "~/analysis/flow_interim/processed_data/all_cohorts_freqSC_2021_05_13.xlsx"
fullFile <- "~/analysis/flow_interim/processed_data/all_cohorts_clin_freqSC_2021_11_17.xlsx"


#Get current file location
srcFile <- NULL
stackPos <- 0
while (is.null(srcFile)) {
  stackPos <- stackPos-1
  srcFile <- sys.frame(stackPos)$srcfile  
}
flowJo_folder <- dirname(srcFile$filename)

#Execute
source(file.path(flowJo_folder, "clinical_proc.R"))
source(file.path(flowJo_folder, "flowJo_proc.R"))

clinDF <- load_clinical_ad_hoc(inFile = clinFile)
dataDF <- read.xlsx(file = dataFile, sheetIndex = 1, 
                     as.data.frame = T, stringsAsFactors = F, check.names = F)
dataDF$Cohort <- as.factor(dataDF$Cohort)

allDF <- merge(x = clinDF, y = dataDF, all.x = F, all.y = T)
df2xlsx(allDF, xlsxFile = fullFile)
