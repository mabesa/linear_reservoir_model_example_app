library(shiny)
library(tidyverse)
library(tsibble)
library(rhandsontable)


server <- function(input, output) {

  experiment_table <- tsibble(`t [s]` = seq(1,11,1),
                              `W [g]` = c(0,29,82,137,184,221,250,268,275, 275, 275),
                              index = `t [s]`) %>%
    mutate(`Qm [ml/s]` = c(0, diff(`W [g]`)))

  reactive_table <- reactiveValues()

  observe({
    if (!is.null(input$dataTable)) {
      reactive_table[["previous"]] <- isolate(reactive_table[["DF"]])
      experiment_table = hot_to_r(input$dataTable)
    } else {
      if (is.null(reactive_table[["DF"]])) {
        experiment_table <- experiment_table
      } else {
        experiment_table <- reactive_table[["DF"]]
      }
    }
    experiment_table$`Qm [ml/s]` <- c(0, diff(experiment_table$`W [g]`))
    reactive_table[["DF"]] <- experiment_table
  })

  output$dataTable <- renderRHandsontable({
    data2display <- reactive_table[["DF"]]
    rhandsontable(data2display, rowHeaders = NULL, height = "2cm") %>%
      hot_col(col = "t [s]", readOnly = TRUE) %>%
      hot_col(col = "Qm [ml/s]", readOnly = TRUE) %>%
      hot_validate_numeric(cols = 2, min = 0)
  })

  output$distPlot <- renderPlot({
    data2show <- reactive_table[["DF"]]
    deltat <- 0.2
    Q0 <- 0

    C1 <- deltat / (2 * input$k + deltat)
    C2 <- (2 * input$k - deltat) / (2 * input$k + deltat)

    dt <- 1
    measurements <- tsibble(second = seq(1, 14, dt),
                            R = 0,
                            index = second)
    measurements$R[1:(3*1/dt)] <- rep(275*dt/3, 3*1/dt)
    L <- dim(measurements)[1]

    measurements$Q <- Q0
    for (t in c(2:L)) {
      measurements$Q[t] <- 2 * C1 * measurements$R[t] + C2 * measurements$Q[t-1]
    }

    colSums(measurements)

    colour_library <- c("R" = "blue", "Q" = "gray40", "Qm" = "black")

    ggplot(measurements) +
      geom_col(aes(second, R, fill = "R"), alpha = 0.8) +
      geom_col(aes(second, Q, fill = "Q"), alpha = 0.8) +
      geom_point(data = data2show, aes(`t [s]`, `Qm [ml/s]`, colour = "Qm")) +
      labs(x = "Time t [s]", y = "Flux [ml]") +
      scale_colour_manual(name = "Measurement", values = colour_library) +
      scale_fill_manual(name = "Simulation", values = colour_library) +
      theme_bw() +
      theme(legend.position = c(0.85, 0.8))
  })

  url <- a("Hydrological Modelling Central Asia", href="https://tobiassiegfried.github.io/HydrologicalModeling_CentralAsia/")
  output$tabCourseLink <- renderUI({
    tagList("This interactive app is part of the course book ", url)
  })

  urlHSOL <- a("hydrosolutions", href="https://www.hydrosolutions.ch")
  output$tabHSOL <- renderUI({
    tagList("Implemented 2021 by ", urlHSOL)
  })

}





