cp_cohort <- function(fromDir, toDir, file_pattern = "FlowJo.*\\.xls$"){
  files <- dir(path = fromDir, pattern = file_pattern, recursive = T)
  fromFiles <- file.path(fromDir, files)
  toFiles <- file.path(toDir, files)
  toDirs <- unique(dirname(toFiles))
  print(toDirs)
  require(purrr)
  walk(toDirs, dir.create, recursive = T)
  file.copy(from = fromFiles, to = toFiles, overwrite = F, recursive = F)
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
