#Install and attach packages
required_packages <- c("purrr", "data.tree", "DiagrammeR", "xlsx", "yaml", "stringr", "plyr", "car")
new_packages <- setdiff(required_packages, rownames(installed.packages()))
install.packages(new_packages)
for (pkg in required_packages){
  library(pkg, character.only = T)
}

load_clinical_ad_hoc <- function(inFile){
  clinDF <- read.xlsx(file = inFile, sheetIndex = 1, 
            as.data.frame = T, stringsAsFactors = T, check.names = F)
  clinDF$`Sample names` <- as.character(clinDF$`Sample names`)
  clinDF$BMI <- bmi2factor(round(as.numeric(levels(clinDF$BMI))[clinDF$BMI], digits = 1))
  clinDF$`Date of blood draw` <- date2factor(clinDF$`Date of blood draw`) 
  clinDF$Age <- round(as.numeric(levels(clinDF$`Age `))[clinDF$`Age `])
  clinDF$`Simple subtype` <- car::recode(clinDF$`Harmonized subtype`, 
                                         "c('ER+HER2+', 'HER2+') = 'HER2+';
                                          'TNBC' = 'TN'")
  clinDF$`Binary stage` <- car::recode(clinDF$`Simple stage`, 
                                         "0 = 'none';
                                         c(1,2,3) = 'early';
                                          4 = 'late'")
  clinDF$StageType <- combine_stage_subtype_V2(clinDF)
  clinI <- c("Cohort", "Sample names", "Harmonized subtype", "Simple subtype", "Simple stage", "Binary stage", "StageType",
             "Node positive", "Date of blood draw", "Age", "BMI", "Grade of tumor")
  
  
  clinDF <- clinDF[clinI]
  
  return(clinDF)
}

combine_stage_subtype_V2 <- function(clinDF){
  stage_subtype <- map2_chr(clinDF$`Binary stage`, clinDF$`Simple subtype`, function(x,y) paste0(x, ":", y))
  NaI <- grep(pattern = "NA", x = stage_subtype, fixed = T)
  stage_subtype[NaI] <- NA_character_
  stage_subtype <- factor(stage_subtype)
  levels(stage_subtype)[levels(stage_subtype) == "none:HD"] <- "HD"
  return(stage_subtype)
}

combine_stage_subtype <- function(clinDF){
  stageI <- clinDF$`Simple stage` == 4
  stage <- rep("e", length(clinDF$`Simple stage`))
  stage[stageI] <- "l"
  stage[is.na(stageI)] <- NA_character_
  
  subtype <- clinDF$`Harmonized subtype`
  old_lvls <- levels(subtype)
  new_lvls <- old_lvls;
  new_lvls[old_lvls == "ER+"] <- "E"
  new_lvls[old_lvls == "ER+HER2+"] <- "EH"
  new_lvls[old_lvls == "HER2+"] <- "H"
  new_lvls[old_lvls == "TNBC"] <- "TN"
  levels(subtype) <- new_lvls
  isnaI <- is.na(subtype) | is.na(stage)
  isHD <- !is.na(subtype) & subtype == "HD"
  
  stage_subtype <- paste(stage, subtype, sep = "_")
  stage_subtype[isnaI] <- NA_character_
  stage_subtype[isHD] <- "HD"
  return(as.factor(stage_subtype))
}

bmi2factor <- function(BMInum, 
                       lvls = c("Underwt.", "Normal", "Overwt.", "Obese", "Ext. Obese"), 
                       thrsh = c(18.5, 25, 30, 35)){

  BMIstr <- rep(NA_character_, length(BMInum))
  thrsh <- c(-Inf, thrsh, Inf)
  for (i in seq_along(thrsh[-1])){
    BMIstr[BMInum >= thrsh[[i]] & BMInum < thrsh[[i+1]]] <- lvls[[i]]
  }
  return(factor(BMIstr, levels = lvls, ordered = T))
}

date2factor <- function(dates, 
                        lvls = c("2017-18", "2019-prePandemic", "inPandemic"), 
                        thrsh = c("2019-01-01", "2020-03-11")){
  
  timeStr <- rep(NA_character_, length(dates))
  thrsh <- c("1900-01-01", thrsh, "2099-12-31")
  for (i in seq_along(thrsh[-1])){
    timeStr[dates >= thrsh[[i]] & dates < thrsh[[i+1]]] <- lvls[[i]]
  }
  return(factor(timeStr, levels = lvls, ordered = T))
}









