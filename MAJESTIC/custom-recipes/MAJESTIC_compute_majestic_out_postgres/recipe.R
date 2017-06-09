# Code for custom code recipe MAJESTIC_compute_majestic_out_postgres (imported from a Python recipe)

# import the classes for accessing DSS objects from the recipe
library(dataiku)

# Inputs and outputs are defined by roles. In the recipe's I/O tab, the user can associate one
# or more dataset to each input and output role.
# Roles need to be defined in recipe.json, in the inputRoles and outputRoles fields.

# To  retrieve the datasets of an input role named 'input_A' as an array of dataset names:
majestic_in = dkuCustomRecipeInputNamesForRole('input_A_role')

# For example, you can read the first input_A_role dataset with
# df <- read.dataset(input_A_names)

# For outputs, the process is the same:
majestic_out = dkuCustomRecipeOutputNamesForRole('main_output')

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
packages <- c("dplyr", "rjson", "urltools", "stringr", "httr")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}


library(dplyr)
library(rjson)
library(urltools)
library(stringr)
library(httr)


apiKey = config["keyAPI"]
urlColumn = config["urlColumn"]

# change to api for prod
# change to developper to sandbox
apiUrl <-"https://api.majestic.com/api/json?app_api_key="

#historic : all period
#refresh : 90 last days
modeUrl <- "historic"


majesticGetInfoUrl <- function(u) {
  u <- url_encode(u)
  url <- paste(apiUrl,apiKey,"&cmd=GetIndexItemInfo&items=1&item0=",u,"&datasource=",modeUrl,sep="")
  req <-GET(url)

  result <- as.data.frame(content(req)$DataTables$Results$Data) %>%
                select(ExtBackLinks,RefDomains,CitationFlow,TrustFlow)
  return(result)
}

# Recipe inputs
semrush_out_csv <- dkuReadDataset(majestic_in) %>%
                    select(contains(urlColumn)) %>%
                    unique()

colnames(semrush_out_csv) <- "Url"

# Find Max
max <- dim(semrush_out_csv)[1]
min <- 1


for ( i in min:max ) {

    #url <- semrush_out_csv$Url[i]
    url <- semrush_out_csv$Url[i]
    
    #print(url)
    tryCatch({
      datatemp <- majesticGetInfoUrl(url)
    
      if (!is.null(datatemp$ExtBackLinks)) {
        semrush_out_csv$ExtBackLinks[i] <- datatemp$ExtBackLinks
        semrush_out_csv$RefDomains[i] <- datatemp$RefDomains
        semrush_out_csv$CitationFlow[i] <- datatemp$CitationFlow
        semrush_out_csv$TrustFlow[i] <- datatemp$TrustFlow
        
        dkuWriteDataset(semrush_out_csv[1:i,],majestic_out)
      }
   })
    
}



