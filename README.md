# Battlesnake-Nessegrev-julia

This is my first Julia project. I made a snake for [Battlesnake](http://play.battlesnake.com)
This is the code used by the snake "Nessegrev-Léa"



## Package Requirement :
-Joseki, used to parse/reply json request/response
-HTTP,  used to receive http request
-Dates,  used to calculated time to response before the timeout
-Distributed,  not used yet, but for testing multi-thread the search


## Getting Started

Install package via julia package management. Example :  import Pkg; Pkg.add("HTTP")
Then execute  julia Nessegrev.jl (in the app folder)
The snake will reply to request to [localhost:8000](http://localhost:8000)


## Configuration

Currently config are hard-coded. My bad...

