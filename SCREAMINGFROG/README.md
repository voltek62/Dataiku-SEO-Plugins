**Install Screaming Frog on your DSS**

$ sudo su dataiku
$ cd /home/dataiku/
$ mkdir crawls

*Prepare*

$ sudo apt-get install default-jre
$ sudo apt-get install cabextract xfonts-utils  
$ wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb  
$ sudo dpkg -i ttf-mscorefonts-installer_3.6_all.deb  
$ sudo apt-get install xdg-utils zenity libgconf-2-4 fonts-wqy-zenhei  

*Install screamingfrog and change by the last version ( here 10.1 )*

$ wget https://download.screamingfrog.co.uk/products/seo-spider/screamingfrogseospider_10.1_all.deb  
$ sudo dpkg -i screamingfrogseospider_10.1_all.deb  

*Test it*

$ screamingfrogseospider --help  
$ rm screamingfrogseospider_10.1_all.deb

$ cd .ScreamingFrogSEOSpider
$ nano licence.txt
add 2 lines with your username and licence-key 

$ nano spider.config
$ add line : eula.accepted=8

*Run and generate : /crawls/internal_html.csv*

screamingfrogseospider --crawl https://data-seo.com --headless --save-crawl --output-folder /home/dataiku/crawls --export-format csv --export-tabs Internal:HTML --overwrite
