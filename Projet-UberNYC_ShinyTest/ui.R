
# ui.R
library(shiny)
library(twitteR)
library(ROAuth)
library(tm)
library(wordcloud)
library(leaflet)
library(dplyr)
library(ggplot2)
library(ggmap)
library(rgdal)
library(zoo)
# library(shinyAce)
# library(sendmailR)

shinyUI(
  fluidPage(
    
    # Application title
    titlePanel("Here's my first Shiny App !"),
    
    
    navbarPage("Super APP", id="nav",
      # tabPanel("Shiny",
      #   
      #   sidebarLayout(
      #     sidebarPanel(
      #       h2("Installation"),
      #       p("Shiny is available on CRAN, so you can install it in the usual way from your R console :"),
      #       code('install.packages("shiny")'),
      #       br(),
      #       br(),
      #       br(),
      #       p(img(src = "~/Kaggle/Sniny/UberNYC/bigorb.png", height = 72, width = 72),
      #         "shiny is a product of ",
      #         span("RStudio", style = "color:blue"),
      #         ".")
      #     ),
      #     mainPanel(
      #       h1("Introducing Shiny"),
      #       p("Shiny is a new package from RStudio that makes it ",
      #         em("incredibly easy"),
      #         " to build interactive web applications with R."),
      #       br(),
      #       p("For an introduction and live examples, visit the ",
      #         a("Shiny homepage.", href = "http://www.rstudio.com/shiny")),
      #       br(),
      #       h2("Features"),
      #       p("* Build useful web applications with only a few lines of code—no JavaScript required."),
      #       p("* Shiny applications are automatically “live” in the same way that ",
      #         strong("spreadsheets"),
      #         " are live. Outputs change instantly as users modify inputs, without requiring a reload of the browser.")
      #     )
      #   )
      # ),
      
      # tabPanel("Send an email",
      # 
      #   sidebarLayout(
      #     sidebarPanel(
      #       h2("Email"),
      #       textInput("from", "From:", value="from@gmail.com"),
      #       # textInput("to", "To:", value="to@gmail.com"),
      #       textInput("subject", "Subject:", value=""),
      #       actionButton("send", "Send mail")
      #     ),
      #     mainPanel(
      #       h2("Introducing ME !"),
      #       h4("I'm Maxime BRIENS !"),
      #       
      #       aceEditor("message", value="write message here")
      #     )
      #   )
      # ),
      
      tabPanel("Presentation",
               
        sidebarLayout(
          sidebarPanel(
            h2("Installation"),
            p("Shiny is available on CRAN, so you can install it in the usual way from your R console :"),
            code('install.packages("shiny")'),
            br(),
            br(),
            br(),
            p(img(src = "bigorb.png", height = 72, width = 72),
              "shiny is a product of ",
              span("RStudio", style = "color:blue"),
              "."),
            br()
          ),
          mainPanel(
            h2("Introducing ME !"),
            h4("I'm Maxime BRIENS !"),
            p("Here's my first Shiny App! You'll find several useless things."),
            br(),
            p("Don't hesitate to have a look on my ",
              a("Linkedin profile",
                href = "https://www.linkedin.com/in/maxime-briens/"),
              "."),
            br(),
            h2("Notice"),
            p("To use this App and all its functionnalities, click on the tabs up-here."),
            # br(),
            p("* ",
              strong("Presentation"),
              " : Here you are !"),
            p("* ",
              strong("Dataviz'1"),
              " : It's nothing else but a basic histogram. (I know you're disapointed ... Sorry!)"),
            p("* ",
              strong("Dataviz'2"),
              " : You'll be impressed, because that one is working with the Tweeter API, and gets live tweets ! (Woah :P)"),
            p("* ",
              strong("Dataviz'3"),
              " : Hold your breath ... Here is an interractive maps that shows some of the Uber pickup points in NYC !",
              span("#incredible", style = "color:blue")),
            br(),
            br(),
            p(strong("COMING SOON"),
              ": You will be able to send me an email straight from the app, to tell me what you think about it, and maybe you could give me some advices or ideas in order to improve it !"),
            p("Meanwhile, my email address is the following : ",
              span("maxbriens@gmail.com", style = "color:blue")),
            br()
          )
        )
      ),
      
      
      tabPanel("Dataviz n°1",
        # Sidebar with a slider input for number of bins 
        sidebarLayout(
          sidebarPanel(
            h2("Histogram"),
            p("So, this is the first tab of my app, which actually is an histogram."),
            p("You can ",
              strong("move the cursor"),
              " down-here, in order to change the graph parameters and change the appearance of the plot."),
            br(),
            sliderInput("bins",
                        "Number of bins:",
                        min = 1,
                        max = 50,
                        value = 30)
          ),
          
          # Show a plot of the generated distribution
          mainPanel(
            plotOutput("distPlot")
          )
        )
      ),
      
      tabPanel("Dataviz n°2",
        # Sidebar with a slider input for number of bins 
        sidebarLayout(
          sidebarPanel(
            h2("Wordcloud"),
            p("That tab will generate a wordcloud !"),
            p(em("PLEASE"), ", be ", strong(em("patient")), "with that tab !"),
            p("You can ",
              strong("type a keyword"),
              " down-here, ",
              strong("click on the 'submit' button"),
              ", and wait nearby 10 seconds."),
            p("It will import the latest Tweets matching with your keyword, and you'll see a plot with the most common words used with the one you wrote."),
            p("If you need ideas, you can try to write ",
              em("'news'"),
              ", ",
              em("'Trump'"),
              ", ",
              em("'movie'"),
              " or maybe even ",
              em("'unicorn'"),
              " ! (dare you ?!?)"),
            br(),
            # selectInput("word", "Text", c("Trump", "Macron")),
            textInput("word", "Text", value = "love"),
            submitButton("Submit")
          ),
          
          # Show a plot of the generated distribution
          mainPanel(
            plotOutput("wordcloud")
          )
        )
      ),
      
      tabPanel("Dataviz n°3",
        # Sidebar with a slider input for number of bins 
        sidebarLayout(
          sidebarPanel(
            h2("Map of NYC"),
            p("That tab will generate an interactive map !"),
            p(em("PLEASE"), ", be ", strong(em("patient")), "with that tab !"),
            p("You can ",
              strong("move the cursor"),
              " down-here to increase the data number, or change the ",
              em("'grouping data'"),
              " option",
              strong(", before clicking on the ",
                     em("'submit'"),
                     "button"),
              ", and wait arround 10 seconds."),
            p("It will plot a ",
              em("leaflet"),
              " map with some of the Uber pickup points arround NYC on april 2014."),
            sliderInput("n_obs", label = "Sliders (x1000)", min = 0, max = 50, value = 20),
            # checkboxInput("opt_choice", label = "Grouping data", value = TRUE),
            radioButtons("opt_choice", label = "Grouping data",
                         choices = list("Yes" = 1, "No" = 2),# "Choice 3" = 3),
                         selected = 1),
            submitButton("Submit")
          ),
          
          # Show a plot of the generated distribution
          mainPanel(
            leafletOutput("map")
          )
        )
      )
    
    
    )
  )
  
)



