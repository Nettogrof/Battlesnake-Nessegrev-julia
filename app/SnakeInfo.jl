mutable struct SnakeInfo
    body::Vector{UInt16}
    name::String
    health::Int16
    eat::Bool
    alive::Bool
end


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

function die(sn::SnakeInfo)

    #sn = SnakeInfo(sn.body,sn.name, sn.health,false, false)
    sn.alive= false
end

function isSnake(sn::SnakeInfo, x::Int)
   
    if (sn.eat)
        if findfirst(isequal(x),sn.body) === nothing
            return false
        else 
          
            return true
          
        end
    else
       
        index = findfirst(isequal(x),sn.body)
      
        if index === nothing
            return false
        else 
           
            return index < length(sn.body) 
           
        end
    end
end

function getHead(sn::SnakeInfo)
    sn.body[1]
end

function getTail(sn::SnakeInfo)
    sn.body[end]
end

function setHealth(sn::SnakeInfo, x::Int)
    if (x == 100)
        sn.eat = true
    end
    sn.health = x
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
    