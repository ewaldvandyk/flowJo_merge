#Install and attach packages
required_packages <- c("purrr", "data.tree", "DiagrammeR", "xlsx", "yaml", "stringr")
new_packages <- setdiff(required_packages, rownames(installed.packages()))
install.packages(new_packages)
for (pkg in required_packages){
  library(pkg, character.only = T)
}


sampDir2dfList <- function(sampDir, pattern = "FlowJo"){
  extPattern <- ".xls$"
  fileNames <- dir(sampDir)
  keepI <- intersect(grep(pattern = extPattern, x = fileNames), grep(pattern = pattern, x = fileNames))
  
  fileNames <- fileNames[keepI]
  
  fullFiles <- map_chr(fileNames, function(x) file.path(sampDir, x))
  df_list <- map(fullFiles, xlsx::read.xlsx, 
                 sheetIndex = 1, 
                 as.data.frame = TRUE, 
                 stringsAsFactors = FALSE, check.names = FALSE)
  return(df_list)
}

cohortDir2dfList <-function(cohortDir, pattern = "FlowJo"){
  sampDirs <- list.dirs(cohortDir, full.names = F, recursive = F)
  df_list <- list()
  for (sampDirName in sampDirs){
    print(paste0("Loading ", sampDirName))
    sampDir <- file.path(cohortDir, sampDirName)
    curr_df_list <- sampDir2dfList(sampDir, pattern = pattern)
    df_list <- c(df_list, curr_df_list)
  }
  return(df_list)
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

colNames2treePaths <- function(colNames){
  treePaths <- gsub(pattern = '\\s*/\\s*', replacement = '/', x = colNames)
  treePaths <- gsub(pattern = '\\|.*$', replacement = '', x = treePaths)
  treePaths <- gsub(pattern = '\\s+$', replacement = '', x = treePaths)
  treePaths <- gsub(pattern = '^\\s+', replacement = '', x = treePaths)
  treePaths <- gsub(pattern = '\\s+', replacement = ' ', x = treePaths)
  treePaths <- gsub(pattern = '\\s+,', replacement = ',', x = treePaths)
  treePaths <- gsub(pattern = ',\\s+', replacement = ', ', x = treePaths)
  return(treePaths)
}

colNames2freqTypes <- function(colNames){
  freqTypes <- gsub(pattern = "^.*\\|", replacement = '', x = colNames)
  freqTypes <- gsub(pattern = "^\\s*", replacement = '', x = freqTypes)
  return(freqTypes)
}

make_ref_tree <- function(dataDir, filePattern = "FlowJo"){
  df_list <- cohortDir2dfList(cohortDir = dataDir, pattern = filePattern)
  sampTree <- dfList2Tree(df_list)
  return(sampTree)
  
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

add_chains_2_ref_tree <- function(inputTree, dataDir, filePattern = "FlowJo"){
  df_list <- cohortDir2dfList(cohortDir = dataDir, pattern = filePattern)
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

get_freq_types <- function(dataDir, filePattern = "FlowJo"){
  df_list <- cohortDir2dfList(cohortDir = dataDir, pattern = filePattern)
  freqTypes <- dfList2freqTypes(df_list)
  return(freqTypes)
}

gen_NA_matrix <- function(dataDir, refTree){
  #Get alias list from refTree
  aliasVec <- refTree$Get('alias')
  keepI <- !is.na(aliasVec)
  aliasVec <- aliasVec[keepI]
  
  #Get all frequency types
  freqTypeVec <- get_freq_types(dataDir)
  # print(freqTypeVec)
  
  #Generate column names with alias and frequency types
  print(freqTypeVec)
  fields <- as.vector(t(outer(aliasVec, freqTypeVec, FUN = mixAliasFreqType)))
  
  #Generate sample name vector
  sampNames <- list.dirs(dataDir, full.names = F, recursive = F)
  
  nCol <- length(fields)
  nRow <- length(sampNames)
  
  naMatrix <- matrix(data = NA, nrow = nRow, ncol = nCol)
  colnames(naMatrix) <- fields
  rownames(naMatrix) <- sampNames
  
  return(naMatrix)
}

fill_matrix <- function(dataDir, refTree, dataMat, pattern = "FlowJo", pathPattern = "^[cC]ell"){
  extPattern <- ".xls$"
  sampNames <- list.dirs(dataDir, full.names = F, recursive = F)
  for (sampName in sampNames){
    sampDir <- file.path(dataDir, sampName)
    df_list <- sampDir2dfList(sampDir, pattern = pattern)
    for (filei in seq_along(df_list)){
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
  }
  return(dataMat)
}

mixAliasFreqType <- function(alias, freqType){
  return(paste0(alias, " (", freqType, ")"))
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
