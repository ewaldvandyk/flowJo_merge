freqDF2ObservedPopPairs <- function(freqDF, fieldPattern = "\\s*\\|\\s*Freq\\.\\s+of\\s*"){
  dfFields <- names(freqDF)
  I <- grep(pattern = fieldPattern, x = dfFields)
  dfFields <- dfFields[I]
  popPairMat <- str_split(string = dfFields, pattern = fieldPattern, simplify = T)
  popPairDF <- data.frame(popMain = popPairMat[,1], popRel = popPairMat[,2], fieldName = dfFields, stringsAsFactors = F)
  return(popPairDF)
}

freqDF2relPopFreq <- function(freqDF, relPop = "Single Cells"){
  #Setup cohort frequency calculator
  popPairDF <- freqDF2ObservedPopPairs(freqDF)
  cohort_calc <- setup_cohort_freqCalc(popPairDF=popPairDF, relPop = relPop)
  

  # Initialize return data.frame
  popFields <- unique(popPairDF$popMain)
  newPopFields <- paste0(popFields, " | Freq. of ", relPop)
  numPops <- length(newPopFields)
  numSamps <- nrow(freqDF)
  newPopMat <- matrix(data = rep(NA_real_, numPops*numSamps), ncol = numPops)
  colnames(newPopMat) <- newPopFields
  newPopDF <- data.frame(freqDF[,1:2], newPopMat, stringsAsFactors = F, check.names = F)
  
  # Go through each sample and population to compute frequency
  for (sampi in seq_along(freqDF[[1]])){
    freqSampDF <- freqDF[sampi,]
    samp_calc <- cohort_calc(freqSampDF = freqSampDF)
    for (popi in seq_along(popFields)){
      currFreq <- samp_calc(popName=popFields[popi])
      newPopDF[[newPopFields[[popi]]]][[sampi]] <- currFreq
    }
  }
  
  return(newPopDF)
}

setup_cohort_freqCalc <- function(popPairDF, relPop = "Single Cells"){
  force(popPairDF)
  force(relPop)

  setup_sample_freqCalc <- function(freqSampDF){
    force(freqSampDF)
    freqLog <- c()
    lockLog <- c()
    
    calcPopFreq <- function(popName){
      # If popName is the relative population then return 100% (Since relPop/relPop = 1)
      if (popName == relPop){
        return(100)
      }
      # Return value if already logged
      if (popName %in% names(freqLog)){
        return(freqLog[[popName]])
      }
      if (popName %in% lockLog){
        return(NA_real_)
      }
      
      lockLog <<- c(lockLog, popName)
      
      mainlockedis <- which(popPairDF$popMain == popName & popPairDF$popRel %in% lockLog)
      rellockedis <- which(popPairDF$popRel == popName & popPairDF$popMain %in% lockLog)
      someLocked <- length(c(mainlockedis, rellockedis)) > 0
      
      mainis <- which(popPairDF$popMain == popName & !(popPairDF$popRel %in% lockLog))
      mainsVec <- rep(NA_real_, length(mainis))
      for (i in seq_along(mainsVec)){
        mainsVec[i] <- (freqSampDF[[popPairDF$fieldName[[mainis[[i]]]]]]/100)*
          calcPopFreq(popPairDF$popRel[[mainis[[i]]]])
      }
      
      relis <- which(popPairDF$popRel == popName & !(popPairDF$popMain %in% lockLog))
      relsVec <- rep(NA_real_, length(relis))
      for (i in seq_along(relsVec)){
        relsVec[i] <- (calcPopFreq(popPairDF$popMain[[relis[[i]]]])*100)/
          freqSampDF[[popPairDF$fieldName[[relis[[i]]]]]]
      }
      calcVec <- c(mainsVec, relsVec)
      if (length(calcVec[!is.na(calcVec)]) > 1){
        print(freqSampDF$`Sample names`)
        print(popName)
        print(popPairDF[mainis,])
        print(popPairDF[relis,])
        print(calcVec)  
      }
      
      calcValue <- mean(calcVec, na.rm = T)
      if (is.nan(calcValue)){
        calcValue <- NA_real_
      }
      
      if (!(is.na(calcValue) && someLocked)){
        currLog <- calcValue
        names(currLog) <- popName
        freqLog <<- c(freqLog, currLog)
      }
      lockLog <<- setdiff(lockLog, popName)
      return(calcValue)
    }
  }
}