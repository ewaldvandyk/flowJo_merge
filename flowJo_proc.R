#Install and attach packages
required_packages <- c("purrr", "data.tree", "DiagrammeR", "xlsx", "yaml", "stringr", "plyr")
new_packages <- setdiff(required_packages, rownames(installed.packages()))
install.packages(new_packages)
for (pkg in required_packages){
  library(pkg, character.only = T)
}

cohortDir2dfList <-function(cohortDir, 
                            file_pattern = "FlowJo.*\\.xls$", 
                            time_pattern = NULL){
  sampDirs <- list.dirs(cohortDir, full.names = F, recursive = F)
  df_list <- list()
  for (sampDirName in sampDirs){
    
    sampDir <- file.path(cohortDir, sampDirName)
    curr_df_list <- sampDir2dfList(sampDir, 
                                   file_pattern = file_pattern, 
                                   time_pattern = time_pattern)
    names(curr_df_list) <- rep(sampDirName, length(curr_df_list))
    df_list <- c(df_list, curr_df_list)
  }
  return(df_list)
}

sampDir2dfList <- function(sampDir, 
                           file_pattern = "FlowJo.*\\.xls$", 
                           time_pattern = NULL){
  if (!is.null(time_pattern)){
    timeDirs <- list.dirs(sampDir, full.names = F, recursive = F)
    keepI <- grep(pattern = time_pattern, x = timeDirs)
    timeDirs <- timeDirs[keepI]
    if (length(timeDirs) == 0){
      return(list())
    } else if (length(timeDirs) > 1){
      warning(paste0("Sample ignored due to ambiguous time points in ", sampDir))
      return(list())
    } else {
      sampDir <- file.path(sampDir, timeDirs[[1]])
    }
  }
  print(paste0("Loading ", sampDir))
  fileNames <- dir(sampDir)
  keepI <- grep(pattern = file_pattern, x = fileNames)
  fileNames <- fileNames[keepI]
  
  fullFiles <- map_chr(fileNames, function(x) file.path(sampDir, x))
  df_list <- map(fullFiles, xlsx::read.xlsx, 
                 sheetIndex = 1, 
                 as.data.frame = TRUE, 
                 stringsAsFactors = FALSE, check.names = FALSE)
  return(df_list)
}

xlsxFileList2df_list <- function(fullFiles){
  df_list <- map(fullFiles, xlsx::read.xlsx, 
                 sheetIndex = 1, 
                 as.data.frame = TRUE, 
                 stringsAsFactors = FALSE, check.names = FALSE)
  return(df_list)
}

merge_cohorts <- function(cohort_names, cohort_dfs){
  for (ci in seq_along(cohort_dfs)){
    numRow <- nrow(cohort_dfs[[ci]])
    cohort_dfs[[ci]] <- cbind(data.frame(Cohort = rep(cohort_names[[ci]])), cohort_dfs[[ci]])
  }
  merged_df <- rbind.fill(cohort_dfs) 
  return(merged_df)
}

merge_blank_cohorts <- function(cohort_names, cohort_dirs){
  df <- data.frame(Cohort=c(), `Sample names`=c(), check.names = F, stringsAsFactors = F)
  for (ci in seq_along(cohort_dirs)){
    sampDirs <- list.dirs(cohort_dirs[[ci]], full.names = F, recursive = F)
    nSamps <- length(sampDirs)
    currDF <- data.frame(Cohort=rep(cohort_names[[ci]], nSamps), 
                         `Sample names`=sampDirs, check.names = F, stringsAsFactors = F)
    df <- rbind.fill(df, currDF)
  }
  return(df)
}


dfList2Tree <- function(df_list, pathPattern = "^[cC]ell"){
  pathStrs <- c()
  for (i in seq_along(df_list)){
    nCol <- length(df_list[[i]])
    currColNames <- names(df_list[[i]])
    keepI <- grep(pattern = pathPattern, x = currColNames)
    currColNames <- currColNames[keepI]
    currPaths <- colNames2treePaths(currColNames)
    pathStrs <- c(pathStrs, currPaths)
  }
  pathStrs <- unique(pathStrs)
  pathStrs <- unique(pathStrsExpand(pathStrs))
  pathAlias <- map_chr(.x = pathStrs, .f = function(x) paste0("<new>", str_split(x, "/")[[1]][[length(str_split(x, "/")[[1]])]]))
  
  # print(pathStrs)
  # print(pathAlias)
  pathDF <- data.frame(pathString = pathStrs, alias = pathAlias, stringsAsFactors = F)
  # print(pathDF)
  tree <- as.Node(pathDF)
  return(tree)
}

pathStrsExpand <- function(pathStrs){
  paths <- c()
  for (i in seq_along(pathStrs)){
    curr_split <- str_split(pathStrs[i], pattern = "/")[[1]]
    currPaths <- c()
    if (length(curr_split) <= 1){
      currPaths <- pathStrs[i]
    } else {
      for (j in 2:length(curr_split)){
        currPaths <- c(currPaths, paste(curr_split[1:j], collapse = "/")) 
      }  
    }
    paths <- c(paths, currPaths)
  }

  return(paths)
}

dfList2freqTypes <- function(df_list, pathPattern = "^[cC]ell"){
  freqTypes <- c()
  for (i in seq_along(df_list)){
    nCol <- length(df_list[[i]])
    currFreqTypes <- names(df_list[[i]])
    keepI <- grep(pattern = pathPattern, x = currFreqTypes)
    currFreqTypes <- currFreqTypes[keepI]
    currFreqTypes <- colNames2freqTypes(currFreqTypes)
    freqTypes <- c(freqTypes, currFreqTypes)
  }
  freqTypes <- unique(freqTypes)
  return(freqTypes)
}

dfList2flowJoColNames <- function(df_list, pathPattern = "^[cC]ell"){
  popColNames <- c()
  for (i in seq_along(df_list)){
    currPopColNames <- names(df_list[[i]])
    keepI <- grep(pattern = pathPattern, x = currPopColNames)
    currPopColNames <- currPopColNames[keepI]
    popColNames <- c(popColNames, currPopColNames)
  }
  return(unique(popColNames))
}

flowJoColNames2PopDf <- function(flowJoColNames, tree, skipRoot = T){
  treePaths <- colNames2treePaths(flowJoColNames, skipRoot)
  relPops <- colNames2freqTypes(flowJoColNames)
  relPaths <- getRelPaths(treePaths, relPops)
  
  popAlias <- map_chr(.x = treePaths, .f = function(x) Navigate(tree, path = x)$alias)
  
  relAlias <- map_chr(.x = relPaths, .f = function(x) Navigate(tree, path = x)$alias)
  a <- data.frame(popAlias = popAlias, relAlias = relAlias, stringsAsFactors = F)
  return(a)
}

colNames2treePaths <- function(colNames, skipRoot = F){
  treePaths <- gsub(pattern = '\\|.*$', replacement = '', x = colNames) # Remove "|freq of ..." string
  if (skipRoot){
    treePaths <- gsub(pattern = '^[^/]*/', replacement = '', x = treePaths)
  }
  splitPaths <- str_split(pattern = "/", string = treePaths)
  splitPaths <- map(.x = splitPaths, .f = process_population_names)
  treePaths <- map_chr(.x = splitPaths, .f = paste, collapse = "/")
  return(treePaths)
}

colNames2freqTypes <- function(colNames){
  freqTypes <- gsub(pattern = "^.*\\|\\s*[fF]req(\\.|uency)\\s*of", replacement = '', x = colNames)
  freqTypes <- process_population_names(freqTypes)
  return(freqTypes)
}

getRelPaths <- function(treePaths, relPops){
  # NB!!! Defaults to parent if relPop not found in treepath
  treePaths <- gsub(pattern = "/[^/]*$", replacement = "", x = treePaths)
  patterns <- paste0(relPops, "/.*$")
  relPaths <- pmap_chr(list(patterns, relPops, treePaths), .f = gsub)
  return(relPaths)
}

process_population_names <- function(popnames){
  popnames <- gsub(pattern = ",", replacement = ' , ', x = popnames)
  popnames <- gsub(pattern = "^\\s+", replacement = '', x = popnames)
  popnames <- gsub(pattern = "\\s+$", replacement = '', x = popnames)
  popnames <- gsub(pattern = "\\s{2,}", replacement = ' ', x = popnames)
  popnames <- gsub(pattern = "\\s+,", replacement = ',', x = popnames)
  return(popnames)
}

tree2yamlFile <- function(tree, refYamlFile) {
  yamlStr <- as.yaml(as.list(tree))
  con <- file(refYamlFile, "w")
  yaml::write_yaml(file = con, x = yamlStr)
  close(con)
  return(tree)
}

load_ref_tree <- function(refYamlFile){
  yaml_str <- read_yaml(file = refYamlFile)
  yaml_lst <- yaml.load(string = yaml_str)
  refTree <- as.Node(yaml_lst)
  
  return(refTree)
  
}

add_chains_2_ref_tree <- function(inputTree, df_list){
  newTree <- dfList2Tree(df_list)
  outputTree <- merge_trees(inputTree, newTree)
  return(outputTree)
}

merge_trees <- function(inputTree, newTree){
  newTreeDF <- get_strPath_alias_df(newTree)
  inputTreeDF <- get_strPath_alias_df(inputTree)
  mergeDF <- merge(inputTreeDF, newTreeDF, by = "pathString", all = T)
  outputTreeDF <- data.frame(pathString = mergeDF$pathString, alias=prioritize_alias(mergeDF$alias.x, mergeDF$alias.y), stringsAsFactors = F)
  keepI <- !is.na(outputTreeDF$alias)
  outputTreeDF <- outputTreeDF[keepI,]
  outputTree <- as.Node(outputTreeDF)
  return(outputTree)
}

prioritize_alias <- function(alias1, alias2){
  for (i in seq_along(alias1)){
    if (is.na(alias1[i])){
      alias1[i] <- alias2[i]
    }
  }
  return(alias1)
}

get_strPath_alias_df <- function(tree){
  b <- tree$Get(attribute = function(node) c(node$pathString, if (is.null(node$alias)) NA else node$alias))
  df <- data.frame(pathString = b[1,], alias = b[2,], stringsAsFactors = F)
}

gen_NA_matrix <- function(df_list, refTree){
  flowJoColNames <- dfList2flowJoColNames(df_list = df_list)
  popDF <- flowJoColNames2PopDf(flowJoColNames, tree = refTree)
  
  fields <- mixAliasFreqType(alias = popDF$popAlias, freqType = popDF$relAlias)
  fields <- unique(fields)
  sampNames <- unique(names(df_list))
  
  nCol <- length(fields)
  nRow <- length(sampNames)
  
  naMatrix <- matrix(data = NA, nrow = nRow, ncol = nCol)
  colnames(naMatrix) <- fields
  rownames(naMatrix) <- sampNames
  
  return(naMatrix)
}

gen_NA_matrix_old <- function(df_list, refTree){
  #Get alias list from refTree
  aliasVec <- refTree$Get('alias')
  keepI <- !is.na(aliasVec)
  aliasVec <- aliasVec[keepI]
  
  #Get all frequency types
  freqTypeVec <- dfList2freqTypes(df_list)
  # print(freqTypeVec)
  
  #Generate column names with alias and frequency types
  print(freqTypeVec)
  fields <- as.vector(t(outer(aliasVec, freqTypeVec, FUN = mixAliasFreqType)))
  
  #Generate sample name vector
  sampNames <- unique(names(df_list))
  
  nCol <- length(fields)
  nRow <- length(sampNames)
  
  naMatrix <- matrix(data = NA, nrow = nRow, ncol = nCol)
  colnames(naMatrix) <- fields
  rownames(naMatrix) <- sampNames
  
  return(naMatrix)
}

fill_matrix <- function(df_list, refTree, dataMat, pathPattern = "^[cC]ell"){
  sampNames <- names(df_list)
  for (filei in seq_along(df_list)){
    sampName <- sampNames[filei]
    currColNames <- names(df_list[[filei]])
    keepI <- grep(pattern = pathPattern, x = currColNames)
    currColNames <- currColNames[keepI]
    popDF <- flowJoColNames2PopDf(currColNames, tree = refTree)
    fields <- mixAliasFreqType(alias = popDF$popAlias, freqType = popDF$relAlias)
    for (coli in seq_along(currColNames)){
      field <- currColNames[[coli]]
      freq <- as.double(sub(pattern = "\\s*%\\s*$", replacement = "", x = df_list[[filei]][[field]][[1]]))
      dataMat[sampName, fields[[coli]]] <- freq
    }
  }
  return(dataMat)
}

fill_matrix_old <- function(df_list, refTree, dataMat, pathPattern = "^[cC]ell"){
  sampNames <- names(df_list)
  for (filei in seq_along(df_list)){
    sampName <- sampNames[filei]
    currColNames <- names(df_list[[filei]])
    keepI <- grep(pattern = pathPattern, x = currColNames)
    currColNames <- currColNames[keepI]
    currTreePaths <- colNames2treePaths(currColNames)
    currTreePaths <- sub(pattern = paste0('^', refTree$name, '/'), replacement = '', x = currTreePaths)
    # print(currTreePaths)
    currFreqTypes <- colNames2freqTypes(currColNames)
    # print(currFreqTypes)
    for (coli in seq_along(currColNames)){
      field <- currColNames[[coli]]
      treePath <- currTreePaths[[coli]]
      freqType <- currFreqTypes[[coli]]
      freq <- as.double(sub(pattern = "\\s*%\\s*$", replacement = "", x = df_list[[filei]][[field]][[1]]))
      refNode <- Navigate(refTree, path = treePath)
      if (is.null(refNode)){
        stop("Cohort contains a chain not found in reference tree. Run 'extend_ref_tree.R'")
      }
      colName <- mixAliasFreqType(refNode$alias, freqType)
      dataMat[sampName, colName] <- freq
      
    }
    
  }
  return(dataMat)
}

mixAliasFreqType <- function(alias, freqType){
  return(paste0(alias, " | Freq. of ", freqType))
}

dataMat2xlsx <- function(dataMat, xlsxFile){
  dataDF <- cbind(data.frame(`Sample names` = rownames(dataMat), check.names = F) , data.frame(dataMat, check.names = F))
  keepColI <- map_lgl(.x = dataDF, .f = function(x) any(!is.na(x)))
  dataDF <- dataDF[keepColI]
  keepRowI <- map_lgl(.x = seq_along(rownames(dataDF)), .f = function(x) any(!is.na(dataDF[x,-1])))
  dataDF <- dataDF[keepRowI,]
  xlsx::write.xlsx(x = dataDF, file = path.expand(xlsxFile), showNA = F, row.names = F)
  return(dataDF)
}

df2xlsx <- function(df, xlsxFile){
  xlsx::write.xlsx(x = df, file = path.expand(xlsxFile), showNA = F, row.names = F)
}

