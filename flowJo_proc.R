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
  pathAlias <- map_chr(.x = pathStrs, .f = function(x) str_split(x, "/")[[1]][[length(str_split(x, "/")[[1]])]])
  
  # print(pathStrs)
  # print(pathAlias)
  pathDF <- data.frame(pathString = pathStrs, alias = pathAlias, stringsAsFactors = F)
  # print(pathDF)
  tree <- as.Node(pathDF)
  return(tree)
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

make_ref_tree <- function(dataDir, filePattern = "FlowJo", refYamlFile){
  sampDirs <- list.dirs(dataDir, full.names = F, recursive = F)
  df_list <- list()
  for (sampDirName in sampDirs){
    sampDir <- file.path(dataDir, sampDirName)
    curr_df_list <- sampDir2dfList(sampDir, pattern = filePattern)
    df_list <- c(df_list, curr_df_list)
  }
  
  sampTree <- dfList2Tree(df_list)
  yamlStr <- as.yaml(as.list(sampTree))
  
  con <- file(refYamlFile, "w")
  yaml::write_yaml(file = con, x = yamlStr)
  close(con)
  return(sampTree)
  
}

get_freq_types <- function(dataDir, filePattern = "FlowJo"){
  sampDirs <- list.dirs(dataDir, full.names = F, recursive = F)
  df_list <- list()
  for (sampDirName in sampDirs){
    sampDir <- file.path(dataDir, sampDirName)
    curr_df_list <- sampDir2dfList(sampDir, pattern = filePattern)
    df_list <- c(df_list, curr_df_list)
  }
  freqTypes <- dfList2freqTypes(df_list)
  return(freqTypes)
}


load_ref_tree <- function(refYamlFile){
  yaml_str <- read_yaml(file = refYamlFile)
  yaml_lst <- yaml.load(string = yaml_str)
  refTree <- as.Node(yaml_lst)
  
  return(refTree)
  
}


gen_NA_matrix <- function(dataDir, refTree){
  #Get alias list from refTree
  aliasVec <- refTree$Get('alias')
  keepI <- !is.na(aliasVec)
  aliasVec <- aliasVec[keepI]
  
  #Get all frequency types
  freqTypeVec <- get_freq_types(dataDir)
  
  #Generate column names with alias and frequency types
  fields <- outer(aliasVec, freqTypeVec, FUN = mixAliasFreqType)
  
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
      currFreqTypes <- colNames2freqTypes(currColNames)
      for (coli in seq_along(currColNames)){
        field <- currColNames[[coli]]
        treePath <- currTreePaths[[coli]]
        freqType <- currFreqTypes[[coli]]
        freq <- as.double(sub(pattern = "\\s*%\\s*$", replacement = "", x = df_list[[filei]][[field]][[1]]))
        refNode <- Navigate(refTree, path = treePath)
        
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
  xlsx::write.xlsx(x = dataDF, file = path.expand(xlsxFile), showNA = F)
}
