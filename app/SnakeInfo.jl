mutable struct SnakeInfo
    body::Vector{UInt16}
    name::String
    health::Int16
    eat::Bool
    alive::Bool
end

#=
    This structure contain info about a SnakeInfo
    Body is a vector of square (int)  Body[1] is the head,  body[end] is the getTail
    Name string of the name of the snake (kind of useless)
    Eat does the snake have eaten (meaning next turn it will grow)
    Alive  or death
=#



#=
 Set the body variabl

 =#
function initBody(bod::Array)
  
    b = Vector{UInt16}()
  
    for  i in 1:length(bod)
        addBody(b,bod[i]["x"] ,bod[i]["y"])
    end
   
    return b
end


function addBody(b::Vector{UInt16}, x::Int ,y::Int)
    push!(b,x*1000 + y)
end



#= 
    Unuseful method 
=#
function die(sn::SnakeInfo)

    #sn = SnakeInfo(sn.body,sn.name, sn.health,false, false)
    sn.alive= false
end

#=

    check if the snake is on that square. Use to check if a snake can move on square next turn
=#

function isSnake(sn::SnakeInfo, square::Int)
   
    if (sn.eat)  #If eat mean the snake will grow
        if findfirst(isequal(square),sn.body) === nothing
            return false
        else 
          
            return true
          
        end
    else   #  Not eat, so a snake can go where the tail is currently
       
        index = findfirst(isequal(square),sn.body)
      
        if index === nothing
            return false
        else 
           
            return index < length(sn.body) 
           
        end
    end
end



function cloneSnake(sn::SnakeInfo)
    SnakeInfo(sn.body,sn.name,sn.health,sn.eat,sn.alive)
end

function createNewSnake(sn::SnakeInfo, m::Int , eat::Bool, hazard::Bool)
   
    body = copy(sn.body)
    name = sn.name
    health = sn.health
    alive = sn.alive
    
   
   
    if eat
        health = 100
        eat = true
    else
       
        health = health - 1
      
    end
   
    pushfirst!(body,m)
    if eat == false
        pop!(body)
    end

    if hazard
        health = health - 15
    end

    if health <= 0 
        alive = false
    end

   
    SnakeInfo(body,name,health,eat, alive)
end

function initSnake(json::Dict)
    infoBody= json["body"]
    body = initBody(infoBody)
    sn = SnakeInfo(body,json["name"],json["health"],json["health"] == 100,true)
end

function isequalSnake(a::SnakeInfo, b::SnakeInfo)
    return a.body .== b.body
end
    