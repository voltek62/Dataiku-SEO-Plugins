# Code for custom code recipe SEMRUSH_compute_semrush_out_csv (imported from a Python recipe)

library(dataiku)

# Inputs and outputs are defined by roles. In the recipe's I/O tab, the user can associate one
# or more dataset to each input and output role.
# Roles need to be defined in recipe.json, in the inputRoles and outputRoles fields.

# For outputs, the process is the same:
output_A_names = dkuCustomRecipeOutputNamesForRole('main_output')

# The configuration consists of the parameters set up by the user in the recipe Settings tab.

# Parameters must be added to the recipe.json file so that DSS can prompt the user for values in
# the Settings tab of the recipe. The field "params" holds a list of all the params for wich the
# user will be prompted for values.

# The configuration is simply a map of parameters:
config = dkuCustomRecipeConfig()

#############################
# Your original recipe
#############################

#autoinstall packages
packages <- c("dplyr", "RCurl", "rjson", "urltools", "stringr", "selectr")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

library(dplyr)
library(RCurl)
library(rjson)
library(urltools)
library(stringr)
library(selectr)

keyAPI = config["keyAPI"]
domain = config["domain"]
country = config["country"] 
limit = config["limit"] 
nbresult = config["nbresult"]
filter = config["filter"] 

semrushGetDomain <- function(domain,country,limit,filter) {
  
  domain <- url_encode(domain)
  
  url <- paste("http://api.semrush.com/?type=domain_organic&key=",keyAPI,"&display_limit=",limit,
               "&export_columns=Ph,Po,Pp,Pd,Nq,Cp,Ur,Tr,Tc,Co,Nr,Td&domain=",domain,
               "&display_sort=tr_desc&database=",country,sep="")
  
  filename <- tempfile()
  f <- CFILE(filename, "wb")

  curlPerform(url = url
              , writedata = f@ref
              , encoding = "UTF-8"
              #, verbose = TRUE
  )
  close(f)
  
  
  result <- read.csv( filename, header = TRUE, sep=";",  encoding = "UFT-8", stringsAsFactors=FALSE) %>%
    filter(!grepl(filter, Keyword)) %>%
    arrange(Position)
  
  return(result)
}


semrushGetTop100organic <- function(keyword,country,nbresult) {
  
  keywordUrl <- url_encode(keyword)
  
  url <- paste("http://api.semrush.com/?type=phrase_organic&key=",keyAPI,"&display_limit=",nbresult,
               "&export_columns=Dn,Ur&phrase=",keywordUrl,"&database=",country,sep="")
  
  filename <- tempfile()
  f <- CFILE(filename, "wb")

  curlPerform(url = url
              , writedata = f@ref
              , encoding = "UTF-8"
              #, verbose = TRUE
  )
  close(f)
  
  
  result <- read.csv( filename, header = TRUE, sep=";",  encoding = "UFT-8", stringsAsFactors=FALSE)  %>%
    mutate(Keyword=keyword)

  result$Position <- seq.int(nrow(result))
  
  result$isTopTen <- FALSE
  result$isTopTen[which(result$Position<=10)] <- TRUE    
  
  return(result)
}



semrush_out_list <- semrushGetDomain(domain,country,limit,filter)

count(semrush_out_list)

for(i in 1:count(semrush_out_list)$n){
  
  keyword <- semrush_out_list$Keyword[i]
  print(keyword)
  
  if (i==1){
    semrush_out_csv <- semrushGetTop100organic(keyword,country,nbresult)
  }
  else {
    semrush_out_csv <- rbind(semrush_out_csv,semrushGetTop100organic(keyword,country,nbresult))
  }  
   
}

# Recipe outputs
dkuWriteDataset(semrush_out_csv,output_A_names)
