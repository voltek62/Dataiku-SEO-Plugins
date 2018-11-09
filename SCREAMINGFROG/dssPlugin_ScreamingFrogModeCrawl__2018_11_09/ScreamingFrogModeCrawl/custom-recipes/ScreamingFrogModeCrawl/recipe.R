library(dataiku)

# Inputs and outputs are defined by roles. In the recipe's I/O tab, the user can associate one
# or more dataset to each input and output role.
# Roles need to be defined in recipe.json, in the inputRoles and outputRoles fields.

# To  retrieve the datasets of an input role named 'input_A' as an array of dataset names:
output_dataset  = dkuCustomRecipeOutputNamesForRole('main_output')

# The configuration is simply a map of parameters:
config = dkuCustomRecipeConfig()

#############################
# Your original recipe
#############################


path_home <- dkuCustomVariable("dip.home")

# /home/dataiku/dss_data/crawls
path_crawls <- file.path(path_home, "crawls")
# create crawls if directory doesn't exist
dir.create(path_crawls, showWarnings = FALSE)

# /home/dataiku/dss_data/managed_datasets/NAMEPROJECT 
path_project <- paste0(path_home,"/managed_datasets/",dkuCustomVariable("projectKey"))

# get your url
myurl <- config["url"]
# get your report
myreport <- config["report"]
# set report name : 33 , 53, 54
myreportname <- gsub(":", " - ", myreport)

myconfig <- paste0(path_project,"/",config["config"])

date <- format(Sys.time(),"%Y.%m.%d.%H.%M.%S")
fileoutput <- paste0(path_crawls,"/logs-",date,".txt")

# launch crawl
system2("screamingfrogseospider", 
                                args = c("--crawl",myurl,"--headless","--save-crawl",
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
dkuWriteDataset(DF,output_dataset)

# delete files
dirdelete <- dirname(path_csv)
filedelete <- fileoutput
system(paste0("rm -f ",filedelete))
system(paste0("rm -rf ",dirdelete))
