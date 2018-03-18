library(shiny)
library(leaflet)

# Define UI for application that draws a histogram
shinyUI(
  navbarPage("Bike Station APP", id = "inTabset",

    tabPanel(title="Home", value="home",
      fluidPage(
        # Application title
        titlePanel("Welcome in the 'BIKE STATION APP' !"),br(),
        
        # Sidebar with a slider input for number of bins 
        sidebarPanel(
          h2("Installation"),
          p("Shiny is available on CRAN, so you can install it in the usual way from your R console :"),
          code('install.packages("shiny")'),
          br(),
          br(),
          br()
        ),
        mainPanel(
          h2("Introducing ME !"),
          h4("I'm Maxime BRIENS !"),
          p("Here's my Shiny App! You'll find several things about city bike stations."),
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
            strong("Home"),
            " : Here you are !"),
          p("* ",
            strong("Test1"),
            " : Nothing here for now !"),
          p("* ",
            strong("Test2"),
            " : Nothing here for now !"),
          br(),
          br()
        )
      )
    ),

    tabPanel(title="Stations", value="stations",
      fluidPage(
        # Application title
        titlePanel("Pick a city and look at where are the stations !"),br(),
        
        # Sidebar with a slider input for number of bins 
        fluidRow(
          column(1, align="center"),
          column(3, align="center",
            actionButton("reset_button", "Reset view"),
            br(), br(),
            radioButtons("opt_choice", label = "Choose a city",
              
              choices = list("Toulouse"=1, "Dublin"=2, "Lyon"=3, "Nantes"=4, "Marseille"=5, "Stockholm"=6, "Luxembourg"=7),
              #choices = list('Brisbane'=1, 'Bruxelles-Capitale'=2, 'Namur'=3, 'Santander'=4, 'Seville'=5, 'Valence'=6, 'Amiens'=7, 'Besancon'=8, 'Cergy-Pontoise'=9, 'Creteil'=10,
              #               'Lyon'=11, 'Marseille'=12, 'Mulhouse'=13, 'Nancy'=14, 'Nantes'=15, 'Rouen'=16, 'Toulouse'=17, 'Dublin'=18, 'Toyama'=19, 'Vilnius'=20,
              #               'Luxembourg'=21, 'Lillestrom'=22, 'Kazan'=23, 'Goteborg'=24, 'Lund'=25, 'Stockholm'=26, 'Ljubljana'=27),
              selected = 1)
          ),
          column(7, align="center",
            leafletOutput("map")
          ),
          column(1, align="center")
        )
      )
    )


  )
)



