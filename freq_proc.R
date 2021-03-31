#Install and attach packages
required_packages <- c("purrr", "data.tree", "DiagrammeR", "xlsx", "yaml", "stringr", "plyr")
new_packages <- setdiff(required_packages, rownames(installed.packages()))
install.packages(new_packages)
for (pkg in required_packages){
  library(pkg, character.only = T)
}

filterOnFlag <- function(freqDF, refTree, flagParam ="stimulated", valueKeep = F, naDefault = F, fieldPattern = "\\s*\\|\\s*Freq\\.\\s+of\\s*"){
  alias <- refTree$Get("alias", traversal = "pre-order")
  flag  <- refTree$Get(flagParam, traversal = "pre-order")
  flag[is.na(flag)] <- naDefault
  aliasKeep <- alias[flag==valueKeep]
  aliasKeep <- aliasKeep[!is.na(aliasKeep)]
  
  popPairDF <- freqDF2ObservedPopPairs(freqDF, fieldPattern)
  colKeep <- popPairDF$fieldName[popPairDF$popMain %in% aliasKeep]
  print(aliasKeep)
  
  dfFields <- names(freqDF)
  metaI <- !grepl(pattern = fieldPattern, x = dfFields)
  dataI <- dfFields %in% colKeep
  
  freqDF <- freqDF[metaI | dataI]
  return(freqDF)
}

freqDF2ObservedPopPairs <- function(freqDF, fieldPattern = "\\s*\\|\\s*Freq\\.\\s+of\\s*"){
  dfFields <- names(freqDF)
  I <- grep(pattern = fieldPattern, x = dfFields)
  dfFields <- dfFields[I]
  popPairMat <- str_split(string = dfFields, pattern = fieldPattern, simplify = T)
  popPairDF <- data.frame(popMain = popPairMat[,1], popRel = popPairMat[,2], fieldName = dfFields, stringsAsFactors = F)
  return(popPairDF)
}

freq2cPerMl <- function(freqPerCellDF, cellPerMlDF, fieldPattern = "\\s*\\|\\s*Freq\\.\\s+of\\s*"){
  common_cols <- intersect(names(freqPerCellDF), names(cellPerMlDF))
  perMlCol <- setdiff(names(cellPerMlDF), common_cols)
  popPairsDF <- freqDF2ObservedPopPairs(freqPerCellDF, fieldPattern = fieldPattern)
  mergedDF <- merge(x = cellPerMlDF, y = freqPerCellDF, all.x = F, all.y = T)
  
  perMlMat <- matrix(data = NA_real_, nrow = nrow(mergedDF), ncol = length(popPairsDF$fieldName))
  colnames(perMlMat) <- paste0(popPairsDF$popMain, " | Count per ML")
  for (i in seq_along(popPairsDF$fieldName)){
    perMlMat[,i] <- mergedDF[[perMlCol]]*mergedDF[[popPairsDF$fieldName[[i]]]]
  }
  countDF <- data.frame(mergedDF[common_cols], perMlMat, check.names = F, stringsAsFactors = F)
  return(countDF)
}

freqDF2relPopFreq <- function(freqDF, refTree, relPop = "Single Cells", flowJoProcEnv){
  #Setup cohort frequency calculator
  popPairDF <- freqDF2ObservedPopPairs(freqDF)
  cohort_calc <- setup_cohort_freqCalc(popPairDF=popPairDF, relPop = relPop)
  
  # Initialize return data.frame
  popFields <- unique(popPairDF$popMain)
  allPaths <- flowJoProcEnv$get_strPath_alias_df(refTree)
  popPaths <- allPaths[allPaths$alias %in% popFields,]
  relPaths <- allPaths[allPaths$alias %in% relPop,]
  popI <- c()
  for (relPath in relPaths$pathString){
    currI <- grep(pattern = relPath, x = popPaths$pathString, fixed = T)
    popI <- union(popI, currI)
  }
  popPaths <- popPaths[popI,]
  popFields <- unique(popPaths$alias)
  
  
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
      currFreqStruct <- samp_calc(popName=popFields[popi])
      newPopDF[[newPopFields[[popi]]]][[sampi]] <- currFreqStruct$freq
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
    depthLog <- c()
    lockLog <- c()
    
    calcPopFreq <- function(popName){
      # If popName is the relative population then return 100% (Since relPop/relPop = 1)
      if (popName == relPop){
        freqStruct <- list(freq = 100, depth = 0)
        return(freqStruct)
      }
      # Return value if already logged
      if (popName %in% names(freqLog)){
        freqStruct <- list(freq = freqLog[[popName]], depth = depthLog[[popName]])
        return(freqStruct)
      }
      if (popName %in% lockLog){
        freqStruct <- list(freq = NA_real_, depth = NA_integer_)
        return(freqStruct)
      }
      
      lockLog <<- c(lockLog, popName)
      
      mainlockedis <- which(popPairDF$popMain == popName & popPairDF$popRel %in% lockLog)
      rellockedis <- which(popPairDF$popRel == popName & popPairDF$popMain %in% lockLog)
      someLocked <- length(c(mainlockedis, rellockedis)) > 0
      
      mainis <- which(popPairDF$popMain == popName & !(popPairDF$popRel %in% lockLog))
      mainsVec <- rep(NA_real_, length(mainis))
      mainDepthVec <- rep(NA_integer_, length(mainis))
      for (i in seq_along(mainsVec)){
        currPopFreqStruct <- calcPopFreq(popPairDF$popRel[[mainis[[i]]]])
        mainsVec[[i]] <- (freqSampDF[[popPairDF$fieldName[[mainis[[i]]]]]]/100)*
          currPopFreqStruct$freq
        mainDepthVec[[i]] <- currPopFreqStruct$depth + 1
      }
      
      relis <- which(popPairDF$popRel == popName & !(popPairDF$popMain %in% lockLog))
      relsVec <- rep(NA_real_, length(relis))
      relDepthVec <- rep(NA_integer_, length(relis))
      for (i in seq_along(relsVec)){
        currPopFreqStruct <- calcPopFreq(popPairDF$popMain[[relis[[i]]]])
        relsVec[[i]] <- (currPopFreqStruct$freq*100)/
          freqSampDF[[popPairDF$fieldName[[relis[[i]]]]]]
        relDepthVec[[i]] <- currPopFreqStruct$depth + 1
      }
      calcVec <- c(mainsVec, relsVec)
      depthVec <- c(mainDepthVec, relDepthVec)
      if (length(calcVec[!is.na(calcVec)]) > 1){
        print(freqSampDF$`Sample names`)
        print(popName)
        print(popPairDF[mainis,])
        print(popPairDF[relis,])
        print(depthVec)
        print(calcVec)  
      }
      
      notNaI <- !is.na(calcVec)
      calcVec <- calcVec[notNaI]
      depthVec <- depthVec[notNaI]
      if (length(calcVec) == 0){
        calcValue <- NA_real_
        currDepth <- NA_integer_
      } else {
        minDepth <- min(depthVec)
        minDepthI <- depthVec == minDepth
        calcValue <- mean(calcVec[minDepthI])
        currDepth <- minDepth
      }
      
      # calcValue <- mean(calcVec, na.rm = T)
      # if (is.nan(calcValue)){
      #   calcValue <- NA_real_
      # }
      
      if (!(is.na(calcValue) && someLocked)){
        currFreqLog <- calcValue
        names(currFreqLog) <- popName
        freqLog <<- c(freqLog, currFreqLog)
        currDepthLog <- currDepth
        names(currDepthLog) <- popName
        depthLog <<- c(depthLog, currDepthLog)
      }
      lockLog <<- setdiff(lockLog, popName)
      freqStruct <- list(freq = calcValue, depth = currDepth)
      return(freqStruct)
    }
  }
}