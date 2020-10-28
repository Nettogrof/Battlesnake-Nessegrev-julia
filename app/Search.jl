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
    for w in 1:200
        generateChild(search, getSmallChild(search.root))
    end
    while ( getTime() - search.startTime < search.timeout && search.root.exp)
        generateChild(search, getSmallChild(search.root)) 
        node = getBestChild(search.root)
        for i in 1:4
            generateChild(search, getBestChild(node))
                   
        end
 
    end
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
                
                    newnode = createNode(move, node.food, node.hazard)
                    newnode.score[1] = 0
                    addChild(node, newnode)
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

