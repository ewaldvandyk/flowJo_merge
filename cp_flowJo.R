cp_cohort <- function(fromDir, toDir, file_pattern = "FlowJo"){
  dir.create(path = toDir, recursive = F, showWarnings = T)
  sampDirs <- list.dirs(fromDir, full.names = F, recursive = T)
  for (sampDir in sampDirs){
    inSampDir <- file.path(fromDir, sampDir)
    outSampDir <- file.path(toDir, sampDir)
    dir.create(path = outSampDir, recursive = T, showWarnings = T)
    cp_sampFiles(inSampDir = inSampDir, outSampDir = outSampDir, file_pattern = file_pattern)
  }
}

cp_sampFiles <- function(inSampDir, outSampDir, file_pattern = "FlowJo"){
  extPattern <- ".xlsx?$"
  fileNames <- dir(inSampDir, recursive = F)
  keepI <- intersect(grep(pattern = extPattern, x = fileNames), grep(pattern = file_pattern, x = fileNames))
  
  fileNames <- fileNames[keepI]
  print(fileNames)
  
  require(purrr)
  fullFiles <- map_chr(fileNames, function(x) file.path(inSampDir, x))
  
  file.copy(from = fullFiles, to = outSampDir, overwrite = F, recursive = F)
  return(fullFiles)
}
