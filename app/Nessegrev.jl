using Joseki, HTTP, Dates, Distributed
addprocs(4)
include("Food.jl")

include("Hazard.jl")
include("SnakeInfo.jl")
include("Node.jl")
include("Search.jl")

println("nbThreads")
println(Threads.nthreads())
global lastRoot = Node()

function index(req::HTTP.Request)
    color = "#FFAAAA"
    headType="shac-gamer"
    tailType="shac-coffee"
    
   dict = Dict("color" => "#FFAAAA", "head" => "shac-gamer", "tail" => "shac-coffee", "apiversion" => "0")
   simple_json_responder(req,dict)
  
end

function ping(req::HTTP.Request)
    render(Text, "ok")
end

function test(req::HTTP.Request)
    nb = 250

    total = 0 
    json = body_as_dict(req)
    bench(json)
    maxtime = 0
    tt=0
   

    for i in 1:nb
        start = getTime()
        total +=  bench(json)
        endtime = getTime()
        tt += endtime-start

        if (endtime - start ) > maxtime
            maxtime = endtime - start
        end
    end

    println("Average")
    println( total / nb / 0.150)
    dict = Dict("Average" => total / nb / 0.150, "Total" => total, "Millisecond average" => tt / nb, "MaxTime" => maxtime)
    simple_json_responder(req,dict)
end

function start(req::HTTP.Request)
    color = "#FFAAAA"
    headType="shac-gamer"
    tailType="shac-coffee"
    
    dict = Dict("color" => "#FFAAAA", "headType" => "shac-gamer", "tailType" => "shac-coffee")
    simple_json_responder(req,dict)
end

function getTime()
    t=now()
    return Dates.hour(t)*60000*60+  Dates.minute(t)*60000 +Dates.second(t)*1000 + Dates.millisecond(t)
end

function bench(json::Dict)
    root = genRoot(json)
   
    t=now()
    start = Dates.hour(t)*60000*60+  Dates.minute(t)*60000 +Dates.second(t)*1000 + Dates.millisecond(t)
    search = Search(true,root,json["board"]["height"],json["board"]["width"],150,start)
    println("Search")
  
   runMulti(search)

    println(root.cc)

  
    return root.cc
end

function move(req::HTTP.Request)
    
    
   
    json = body_as_dict(req)
  
    root = genRoot(json)
  
    t=now()
    start = Dates.hour(t)*60000*60+  Dates.minute(t)*60000 +Dates.second(t)*1000 + Dates.millisecond(t)
    search = Search(true,root,json["board"]["height"],json["board"]["width"],200,start)
  
   
    run(search)
    
   
    winner = chooseBestMove(root)
    shout = ""
    if getScoreRatio(winner) < 0.001
      
        shout="I lost"
        winner = lastChance(root)
        
    elseif getScoreRatio(winner) > 10
        shout="I won"
        #TODO finishHim
    end
   
    move = winner.snakes[1].body[1]
   

    snakex = json["you"]["body"][1]["x"]
    snakey = json["you"]["body"][1]["y"]
  
    if move ÷ 1000 < snakex
        
        direction="left"
    elseif move ÷ 1000 > snakex
        
        direction="right"
    elseif move % 1000 < snakey
       
        direction="up"
    else
       
        direction="down"
    end
    #directions = ["up", "down", "left", "right"]
    #direction = rand(directions)
    
    t=now()
    endtime = Dates.hour(t)*60000*60+  Dates.minute(t)*60000 +Dates.second(t)*1000 + Dates.millisecond(t)
    nodecount = root.cc
    timetotal = endtime-start
    average = (nodecount/timetotal) * 1000
    println("count: $nodecount    time: $timetotal    average: $average ")
    response = Dict("move"=>direction , "shout"=>shout)
    println(response)
    lastRoot = root
    simple_json_responder(req,response)
end

function lastChance(root::Node)
    nb = 0
    ret = root.child[1]
  
    scoreCount = Dict{Int, Int}()
    for c in root.child
        if haskey(scoreCount,c.snakes[1].body[1])
          
            scoreCount[c.snakes[1].body[1]] =  scoreCount[c.snakes[1].body[1]] + c.cc
            
        else
           
            scoreCount[c.snakes[1].body[1]] = c.cc
        end
    end
    
   
    for c in root.child
       
        if scoreCount[c.snakes[1].body[1]] > nb
          
            nb = scoreCount[c.snakes[1].body[1]]
            ret = c 
        end
    end
  
    return ret
end

function countTree( child::Node)
    num = 0 
    if (length(child.child) > 0)
        for c in child.child
           num += countTree(c)
        end  
    else
        return 1   
    end
    return num
end
function genRoot(json::Dict)
    
   
    fi = initFood(json["board"]["food"])
   
   # hi = inithazard(json["board"]["hazard"])
    h=Vector{UInt16}()
    hi = Hazard(h)
   
    snakes = Vector{SnakeInfo}()
    
   
  
    ser =  initSnake(json["you"])
    push!(snakes,ser )
   
   
    myid = json["you"]["id"]
   
    score = Vector{Float16}()
    for s in json["board"]["snakes"]
       
        if (s["id"] != myid)
            push!(snakes, initSnake(s))

            
       end
       push!(score, 0)
    end   
   
   root = Node(fi,hi,1,snakes,Vector{Node}(),true,score,0)
  
  #  if lastRoot.cc > 0
   #     for c in lastRoot.child
    #        println("in")
     #       if isequalroot(c, root)
      #          return c
       #     end
    

        #end
    #end
  
   setScore(root)
   return root
    
end


    
function chooseBestMove(root::Node)
  
    up = Vector{Float16}()
    down = Vector{Float16}()
    right = Vector{Float16}()
    left = Vector{Float16}()

    head = root.snakes[1].body[1]
 
    for i in 1:length(root.child)
        
        move = root.child[i].snakes[1].body[1]
      
        if (move ÷ 1000 < head ÷ 1000) 
            push!(left,getScoreRatio(root.child[i]))
          
        end

        if (move ÷ 1000 > head÷1000) 
            push!(right,getScoreRatio(root.child[i]))
          
        end
        if (move % 1000 < head % 1000) 
            push!(up,getScoreRatio(root.child[i]))
        end
        if (move % 1000 > head % 1000) 
            push!(down,getScoreRatio(root.child[i]))
        end
    end
  
    wup =9999.99
    
    wdown =9999.99
    wleft =9999.99
    wright =9999.99

    for v in up 
        if v < wup
            wup =v
        end
    end

    for v in down 
        if v < wdown
            wdown =v
        end
    end
   
    for v in right
        if v < wright
            wright =v
        end
    end

    for v in left 
        if v < wleft
            wleft =v
        end
    end
  
    choiceValue = -1.0
    winnermove = 0 
    if (wup != 9999.99)
        println("up $wup")
     
        if wup > choiceValue
            choiceValue = wup
            winnermove = head - 1
        end   
    end

    if (wdown != 9999.99)
        println("down $wdown")
       
        if wdown > choiceValue
            choiceValue = wdown
            winnermove = head + 1
        end   
    end

    if (wleft != 9999.99)
        println("left $wleft")
     
        if wleft > choiceValue
            choiceValue = wleft
            winnermove = head - 1000
        end   
    end

    if (wright != 9999.99)
        println("right $wright")
      
        if wright > choiceValue
            choiceValue = wright
            winnermove = head + 1000
        end   
    end
  
    
    
    for i in 1:length(root.child)
        c = getScoreRatio(root.child[i])
      
        if c == choiceValue && root.child[i].snakes[1].alive && root.child[i].snakes[1].body[1] == winnermove
           
            return root.child[i]
        end
    end
    
    return root.child[1]

end


function endGame(req::HTTP.Request)
    simple_json_responder(req,"")
end



endpoints = [
    (index, "GET", "/"),
    (ping, "POST", "/ping"),
    (start, "POST", "/start"),
    (move, "POST", "/move"),
    (test, "POST", "/test"),
    (endGame, "POST", "/end"),
    
]
r = Joseki.router(endpoints)

# Fire up the server
println("Server up")
HTTP.serve(r, "0.0.0.0", 8000; verbose=false, reuseaddr=true)
println("Server up")
