#Install and attach packages
required_packages <- c("purrr", "data.tree", "DiagrammeR", "xlsx", "yaml", "stringr", "plyr")
new_packages <- setdiff(required_packages, rownames(installed.packages()))
install.packages(new_packages)
for (pkg in required_packages){
  library(pkg, character.only = T)
}

load_clinical_ad_hoc <- function(inFile){
  clinDF <- read.xlsx(file = inFile, sheetIndex = 1, 
            as.data.frame = T, stringsAsFactors = T, check.names = F)
  clinDF$`Sample names` <- as.character(clinDF$`Sample names`)
  clinDF$BMI <- round(as.numeric(levels(clinDF$BMI))[clinDF$BMI], digits = 1)
  clinDF$Age <- round(as.numeric(levels(clinDF$`Age `))[clinDF$`Age `])
  clinDF$StageType <- combine_stage_subtype(clinDF)
  clinI <- names(clinDF) %in% c("Cohort", "Sample names", "Harmonized subtype", "Simple stage", 
                                "Node positive", "Age", "BMI", "Grade of tumor", "StageType")
  
  stage_type <- combine_stage_subtype(clinDF)
  
  clinDF <- clinDF[clinI]
  
  return(clinDF)
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