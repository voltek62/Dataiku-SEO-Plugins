library(dataiku)

# Inputs and outputs are defined by roles. In the recipe's I/O tab, the user can associate one
# or more dataset to each input and output role.
# Roles need to be defined in recipe.json, in the inputRoles and outputRoles fields.

# To  retrieve the datasets of an input role named 'input_A' as an array of dataset names:
urls_in = dkuCustomRecipeInputNamesForRole('input_A_role')

# For example, you can read the first input_A_role dataset with
# df <- dkuReadDataset(input_A_names[1])

# For outputs, the process is the same:
urls_out = dkuCustomRecipeOutputNamesForRole('main_output')

# The configuration consists of the parameters set up by the user in the recipe Settings tab.

# Parameters must be added to the recipe.json file so that DSS can prompt the user for values in
# the Settings tab of the recipe. The field "params" holds a list of all the params for wich the
# user will be prompted for values.

# The configuration is simply a map of parameters:
config = dkuCustomRecipeConfig()

print(config["parameter_name"])

#############################
# Your original recipe
#############################

#autoinstall packages
packages <- c("dplyr")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

library(dplyr)

path_home <- dkuCustomVariable("dip.home")

# /home/dataiku/dss_data/crawls
path_crawls <- file.path(path_home, "crawls")
# create crawls if directory doesn't exist
dir.create(path_crawls, showWarnings = FALSE)

# /home/dataiku/dss_data/managed_datasets/NAMEPROJECT 
path_project <- paste0(path_home,"/managed_datasets/",dkuCustomVariable("projectKey"))

urlColumn = config["urlColumn"]

myList <- dkuReadDataset(urls_in) %>%
                    select(contains(urlColumn)) %>%
                    unique()

colnames(myList) <- "Url"
myListURL <- myList$Url

# get your report
myreport <- config["report"]
# set report name
myreportname <- gsub(":", " - ", myreport)

myconfig <- paste0(path_project,"/",config["config"])

date <- format(Sys.time(),"%Y.%m.%d.%H.%M.%S")

fileoutput <- paste0(path_crawls,"/logs-",date,".txt")
filelist <- paste0(path_crawls,"/list-",date,".txt")

write.table(myListURL, filelist, row.names = FALSE, col.names = FALSE, quote=FALSE)

# launch crawl
system2("screamingfrogseospider", 
                                args = c("--crawl-list",filelist,"--headless","--save-crawl",
                                       "--output-folder",path_crawls,"--export-format","csv", 
                                       "--export-tabs",myreport,"--overwrite",
                                       "--config",myconfig,  
                                       "--timestamped-output"),
                                stdout = fileoutput,
                                wait = TRUE )

t1 <- readLines(fileoutput)

# Extract CSV filename
i <- grep(paste0("Writing report ",myreportname," to ",path_crawls,"/"), t1)
path <- strsplit(t1[i],paste0(myreportname," to "))
path_csv <- path[[1]][2]

DF <- read.csv(path_csv, sep=",", skip=1 , check.names=FALSE)

# Recipe outputs
dkuWriteDataset(DF,urls_out)

# delete files
dirdelete <- dirname(path_csv)
filedelete <- fileoutput
system(paste0("rm -f ",filedelete))
system(paste0("rm -f ",filelist))
system(paste0("rm -rf ",dirdelete))


