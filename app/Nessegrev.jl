using Joseki, HTTP, Dates, Distributed, ConfParser


#=  This is my first project in Julia, please be advise several things may be optimized, 
    and it probably not as fast as it should be.  I know that Julia should be faster than Java,
    but currently this implmentation is bit slower than my Java counter-part.

    This implementation use the version 0 board reference: meaning that the top-right square is the "0,0"
    For reference most of the code use a Int to define a square:  X *1000 + Y    
    So  Square 0,0 will equals 0  
        Square 4,7 will equals 4007
=#
gh = 11
gw = 11

addprocs(4)  #Trying to multithread my code,  currently not using it except in benchmark
snakeConf="snake.conf"
include("Food.jl")
include("Hazard.jl")
include("SnakeInfo.jl")
include("Node.jl")
include("Search.jl")
include("MainSnake.jl")


