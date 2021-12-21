# Notice for running the Linkedin search
#### Web-scrapping tool for the Linkedin sales navigator

<br>

<div><img src="https://review.chinabrands.com/chinabrands/seo/image/20190215/linkedin%20sales%20navigator.png" width="600" height="300"/></div>

<br>

## Content description

The Linkedin search includes 2 dependent components :
* The **account scrapping** :

  From a URL of a saved search in the sales navigator, the linkedin search will explore the different pages, one by one, up to 40, in order to gather and write down in a .csv file up to 1000 companies at a time, that all match your filters.

  *It saves the following information : company name, linkedin URL, location, sector, size*

* The **prospect search** :

  From the resulting .csv file(s) of the account scrapping, the prospect search will explore one by one every linkedin page of the companies that we gathered data about in order to enrich this data, as well as searching for some recommended leads to try to reach out to.
  
  *It saves the following information : company URL, prospect name, linkedin URL, role, seniority, location*

## Using the Linkedin search for the first time

If you want to use the Linkedin search for the first time :

  1. Install Firefox
  2. Install Python (version 3)
  3. Install gecko driver
  4. Install the requirements

## How to run the scrapping

To run the search, do the folling steps :
  1. Open the file `parameters.yml`, and edit its field if needed :
     * Update the `username` and the `password` field according to your linkedin credentials
     * Change the value of `pages_to_scrap` according to the number of pages that the linkedin accounts search should go through (Linkedin allows it up to 40)
     * Change the values of `URLs` according to the distinct filters that you'd like to apply the scrapping on
     
     NB : in `URLs` you can also edit the names so that you can better manage your different saved searches. You will find the names of the searches on the resulting csv files.
  2. In a terminal, run the file `wrapper.py` 
  3. A Firefox window should open, start the account scrapping and automatically browsing and moving from one page to another.
  4. You can follow the progress in the console, with the progress bar
  