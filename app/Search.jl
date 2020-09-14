mutable struct Search
    cont::Bool
    root::Node
    height::UInt8
    width::UInt8
    timeout::Int16
    startTime::Int64


end

#=
    This structure is the main search 
    cont: Should continue the search
    Root of the tree search

    height and with of the board

    timeout : time allowed for stopSearching
    startTime when the search started

=#



#=
    Search loop
    search until timeout reach or root cannot be expanded
=#
function run(search::Search)
    while ( getTime() - search.startTime < search.timeout && search.root.exp)
     #   generateChild(search, getSmallChild(search.root))  
        generateChild(search, getBestChild(search.root))
          
    end
end


function runDeep(search::Search)
    while ( getTime() - search.startTime < search.timeout && search.root.exp)
       # generateChild(search, getSmallChild(search.root))  
        generateChild(search, getBestChild(generateChild(search, getBestChild(generateChild(search, getBestChild(generateChild(search, getBestChild(search.root))))))))
          
    end
end


function runDeeper(search::Search)
    for w in 1:100
        generateChild(search, getSmallChild(search.root))
    end
    while ( getTime() - search.startTime < search.timeout && search.root.exp)
        generateChild(search, getSmallChild(search.root)) 
        node = getBestChild(search.root)
        for i in 1:5
            generateChild(search, getBestChild(node))
         
            
        end

        if node.exp
            for i in 1:5
                generateChild(search, getBestChild(node))
                        
            end
        end

        if node.exp
            for i in 1:5
                generateChild(search, getBestChild(node))
                        
            end
        end
  
    end

    #=
    println(search.root.cc)
    n=getBestChild(search.root)
    println(n)
    println("Generate")
    m=generateChildDebug(search, n)
    println(m)
    println("legh")
    println(length(n.child))
    println(length(m.child))


    println(n)


    
    println(n.snakes[1].name)
    for i in 1 : length(n.snakes[1].body)
    println(n.snakes[1].body[i])
    end
    println(n.snakes[2].name)
    for i in 1 : length(n.snakes[1].body)
    println(n.snakes[2].body[i])
    end
    println(n.snakes[3].name)
    for i in 1 : length(n.snakes[1].body)
        println(n.snakes[3].body[i])
        end
    println(n.snakes[4].name)
    for i in 1 : length(n.snakes[1].body)
        println(n.snakes[4].body[i])
        end
=#

end

#=
    Search spliting for multitreading
        Not use yet

=#
function runMulti(search::Search)
   
    t = now()
    generateChild(search, search.root)
    nbThread = nprocs()
    ret = Vector{Task}()
    cv = Vector{Vector{Node}}()

    for i in 1:nbThread
        push!(cv, Vector{Node}())
    end
   
    for i in 1:length(search.root.child)
          id = i % nbThread + 1
            push!(cv[id], search.root.child[i])
      
    end
    @sync for i in 1:nbThread
        @async singleChild(search, cv[i])
    end
  
    updateScore(search.root)
    
end

#=
    Single search in case of multithread.
    Not use
=#

function singleChild(search::Search, child::Vector{Node})
    
    while ( getTime() - search.startTime < search.timeout )
    
        for c in child
            if (c.exp)
                generateChild(search, getSmallChild(c))
                
            end
        end
                    
    end

end


#=
    Not use  may be deleted in future
=#
function stopSearching(search::Search)
    search.cont = false
end

#=
    This method generate child of the node
=#

function generateChild(search::Search, node::Node)
    
    if length(node.child) > 0
        node.exp = false  # If node already have child, means thats the node already have ben expanded  and should not anymore.
    
    else
    
        current = node.snakes
        alphaMove = multi(search, current[1], node.food, current, node.hazard)
    
        node.possibleMove = length(alphaMove)
    
        if length(alphaMove) == 0
            die(node.snakes[1])
            node.exp = false
            node.score[1] = 0
        else
        
            moves = Vector{Vector{SnakeInfo}}()
            nbSnake = length(current)
            moves = merge(moves, alphaMove)
            @inbounds for i in 2:nbSnake
                moves = merge(moves, multi(search, current[i], node.food, current, node.hazard))
            end

            clean(moves)
            stillAlive = false
            @inbounds for move in moves
            
                if move[1].alive
                
                    addChild(node, createNode(move, node.food, node.hazard))
                    stillAlive = true
                else
                
                    node = createNode(move, node.food, node.hazard)
                    node.score[1] = 0
                    addChild(node, node)
                end

            
            end
        
            if stillAlive == false
                die(node.snakes[1])
                node.exp = false
                node.score[1] = 0
            end

        end
    end

end


function generateChildDebug(search::Search, node::Node)
    println("1")
    if length(node.child) > 0
        node.exp = false  # If node already have child, means thats the node already have ben expanded  and should not anymore.
    
    else
        println("2")
        current = node.snakes
        alphaMove = multi(search, current[1], node.food, current, node.hazard)
    
        node.possibleMove = length(alphaMove)
        println("3 $node.possibleMove")
        if length(alphaMove) == 0
            println("die?!")
            die(node.snakes[1])
            node.exp = false
            node.score[1] = 0
        else
            println("4")
            moves = Vector{Vector{SnakeInfo}}()
            nbSnake = length(current)
            moves = merge(moves, alphaMove)
            @inbounds for i in 2:nbSnake
                moves = merge(moves, multi(search, current[i], node.food, current, node.hazard))
            end
            println("5")
            clean(moves)
            stillAlive = false
            @inbounds for move in moves
            
                if move[1].alive
                  
                    addChild(node, createNode(move, node.food, node.hazard))
                    stillAlive = true
                else
                   
                    node = createNode(move, node.food, node.hazard)
                    node.score[1] = 0
                    addChild(node, node)
                end

                
            end
        
            if stillAlive == false
                die(node.snakes[1])
                node.exp = false
                node.score[1] = 0
            end

        end
    end
    println(length(node.child))
    node
end

#=
    Generate possible move for a snake
=#

function multi(search::Search, s::SnakeInfo, f::Food, all::Vector{SnakeInfo}, h::Hazard)

    ret = Vector{SnakeInfo}()

    if s.alive
        head = s.body[1]
    
        newhead = head
    
        if (head ÷ 1000 > 0) 
            newhead = head - 1000;
            if freeSpace(newhead, all)
            
                push!(ret, createNewSnake(s, newhead, foodContain(f, newhead), hazardContain(h, newhead)))
            
            end
        end
    
        if (head ÷ 1000 < search.width - 1) 
            newhead = head + 1000;
            if (freeSpace(newhead, all)) 
                push!(ret, createNewSnake(s, newhead, foodContain(f, newhead), hazardContain(h, newhead)))
            end
        end

        if (head % 1000 > 0) 
        
            newhead = head - 1;
            if (freeSpace(newhead, all)) 
                push!(ret, createNewSnake(s, newhead, foodContain(f, newhead), hazardContain(h, newhead)))
            end
        end

        if (head % 1000 < search.height - 1) 
            newhead = head + 1;
            if (freeSpace(newhead, all)) 
                push!(ret, createNewSnake(s, newhead, foodContain(f, newhead), hazardContain(h, newhead)))
            end
        
        end            
    end

    return ret
end

#=
    Check if the square is empty
=#
function freeSpace(square::Int, snakes::Vector{SnakeInfo})

    free = true
    @simd for i in 1:length(snakes)
        if free
            if isSnake(snakes[i], square)
                free = false
            end
        
        end
    end

    return free
end

#=
    Clean the moves list by "killing" snake in head-to-head
=#

function clean(moves::Vector{Vector{SnakeInfo}})

    @inbounds for move in moves
        @inbounds for i in 1:length(move) - 1
            @inbounds for j in i + 1:length(move)
                if move[i].body[1] == move[j].body[1]
                    firstl = length(move[i].body)
                    secondl = length(move[j].body)

                    if firstl > secondl
                        die(move[j])
                    elseif firstl == secondl
                        die(move[i])
                        die(move[j])
                    else
                        die(move[i])
                    end

                end
            end
        end
    end

end


#=
   Merge two list of move
=#

function merge(list::Vector{Vector{SnakeInfo}}, sn::Vector{SnakeInfo})

    if length(sn) == 0
        return list
    else
        ret  = Vector{Vector{SnakeInfo}}()
    
        if length(list) == 0
            @inbounds for si in sn
                m = Vector{SnakeInfo}()
                push!(m, si)
                push!(ret, m)

            end
        else
            @inbounds for sni in sn
                @inbounds for s in list
                    m = Vector{SnakeInfo}()
                    @inbounds for si in s
                        push!(m, cloneSnake(si))
                    end
                    push!(m, cloneSnake(sni))
                    push!(ret, m)
                end
            end
        end
    
        return ret
    end   
end

