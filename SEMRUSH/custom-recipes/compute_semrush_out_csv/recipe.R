library(dataiku)

# For outputs, the process is the same:
output_dataset = dkuCustomRecipeOutputNamesForRole('main_output')

# The configuration consists of the parameters set up by the user in the recipe Settings tab.

# Parameters must be added to the recipe.json file so that DSS can prompt the user for values in
# the Settings tab of the recipe. The field "params" holds a list of all the params for wich the
# user will be prompted for values.

# The configuration is simply a map of parameters:
config = dkuCustomRecipeConfig()

#############################
# Your original recipe
#############################

library(dplyr)
library(RCurl)
library(rjson)
library(stringr)
#library(selectr)

### API SEMRUSH
keyAPI <- config["key"]
domain <- config["domain"]
country <- config["country"]
limit <- config["limit"]
nbresult <- 100
# filter brand
filter <- config["filter"]

semrushGetDomain <- function(domain,country,limit,filter) {
  
  domain <- str_replace_all(domain, " ", "%20")
  
  url <- paste("http://api.semrush.com/?type=domain_organic&key=",keyAPI,"&display_limit=",limit,
               "&export_columns=Ph,Po,Pp,Pd,Nq,Cp,Ur,Tr,Tc,Co,Nr,Td&domain=",domain,
               "&display_sort=tr_desc&database=",country,sep="")
    
  print(url)
  
  result <- read.csv( url, header = TRUE, sep=";",  encoding = "UFT-8", stringsAsFactors=FALSE) %>%
    filter(!grepl(filter, Keyword)) %>%
    arrange(Position)
  
  return(result)
}


semrushGetTop100organic <- function(keyword,country,limit) {
  
  keywordUrl <- str_replace_all(keyword, " ", "%20")
    
  url <- paste("http://api.semrush.com/?type=phrase_organic&key=",keyAPI,"&display_limit=",limit,
               "&export_columns=Dn,Ur&phrase=",keywordUrl,"&database=",country,sep="")
    
    
  print(url)
  
  result <- read.csv( url, header = TRUE, sep=";",  encoding = "UFT-8", stringsAsFactors=FALSE)  %>%
    mutate(Keyword=keyword)
  
  result$Position <- seq.int(nrow(result))
  
  result$isTopTen <- FALSE
  result$isTopTen[which(result$Position<=10)] <- TRUE    
  
  return(result)
}



semrush_out_list <- semrushGetDomain(domain,country,limit,filter)

for(i in 1:count(semrush_out_list)$n){
  
  keyword <- semrush_out_list$Keyword[i]
  
  if (i==1){
    semrush_out_csv <- semrushGetTop100organic(keyword,country,nbresult)
  }
  else {
    temp <- semrushGetTop100organic(keyword,country,nbresult)
    semrush_out_csv <- bind_rows(semrush_out_csv, temp)
  }  

}

# Recipe outputs
dkuWriteDataset(semrush_out_csv, output_dataset)
