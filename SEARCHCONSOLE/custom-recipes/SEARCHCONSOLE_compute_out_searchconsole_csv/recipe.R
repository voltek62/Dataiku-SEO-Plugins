# Code for custom code recipe SEARCHCONSOLE_compute_out_searchconsole_csv (imported from a Python recipe)

# To finish creating your custom recipe from your original R recipe, you'll need to:
#  - Declare the input and output roles in recipe.json
#  - Replace the dataset names by roles access in your code
#  - Declare, if any, the params of your custom recipe in recipe.json
#  - Replace the hardcoded params values by acccess to the configuration map

# See sample code below for how to do that.
# The code of your original recipe is included afterwards for convenience.
# Please also see the "recipe.json" file for more information.

# import the classes for accessing DSS objects from the recipe
library(dataiku)

# Inputs and outputs are defined by roles. In the recipe's I/O tab, the user can associate one
# or more dataset to each input and output role.
# Roles need to be defined in recipe.json, in the inputRoles and outputRoles fields.

# For example, you can read the first input_A_role dataset with
# df <- read.dataset(input_A_names)

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
packages <- c("googleAuthR", "searchConsoleR")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

#init
current.folder <- getwd()
path.oauth <- paste(dkuManagedFolderPath(toString(config["managed_folderpath"])),"/",".httr-oauth",sep="")
#path.oauth <- paste(dkuManagedFolderPath("token_searchconsole"),"/",".httr-oauth",sep="")

file.copy(path.oauth, current.folder, overwrite=TRUE)

library(googleAuthR)
library(searchConsoleR)

options("searchConsoleR.client_id" = config["client_id"])
options("searchConsoleR.client_secret" = config["client_secret"]) 

## change this to the website you want to download data for. Include http
#website <- "https://data-seo.fr"
website <- toString(config["website"])

## data is in search console reliably 3 days ago, so we donwnload from then
## today - 3 days
start <- Sys.Date() - 3 - as.integer(config["period"])
## one days data, but change it as needed
end <- Sys.Date() - 3 

## what to download, choose between data, query, page, device, country
download_dimensions <- c('date','query','page','device','country')

## what type of Google search, choose between 'web', 'video' or 'image'
type <- c('web')

## other options available, check out ?search_analytics in the R console

## Authorize script with Search Console.  
## First time you will need to login to Google,
## but should auto-refresh after that so can be put in 
## Authorize script with an account that has access to website.
#scr_auth()
googleAuthR::gar_auth()

## first time stop here and wait for authorisation

## get the search analytics data
data <- search_analytics(siteURL = website, 
                         startDate = start, 
                         endDate = end, 
                         dimensions = download_dimensions, 
                         searchType = type)


# Recipe outputs
dkuWriteDataset(data,output_A_names)
