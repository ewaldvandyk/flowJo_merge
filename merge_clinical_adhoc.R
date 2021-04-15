clinFile <- "~/data/Hannah/blood_flowJo/2021_03_25/all_cohorts_clinical_2021_03_31_EVD.xlsx"
perMlFile <- "~/analysis/flow_interim/processed_data/all_cohorts_perML_2021_04_08_v2.xlsx"
fullFile <- "~/analysis/flow_interim/processed_data/all_cohorts_clin_perML_2021_04_13.xlsx"


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
perMlDF <- read.xlsx(file = perMlFile, sheetIndex = 1, 
                     as.data.frame = T, stringsAsFactors = F, check.names = F)
perMlDF$Cohort <- as.factor(perMlDF$Cohort)

dataDF <- merge(x = clinDF, y = perMlDF, all.x = F, all.y = T)
dataDF$BMI <- bmi2factor(dataDF$BMI)
df2xlsx(dataDF, xlsxFile = fullFile)
