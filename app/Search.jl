mutable struct Search
    cont::Bool
    root::Node
    height::UInt8
    width::UInt8
    timeout::Int16
    startTime::Int64


end

function run(search::Search)
    while ( getTime() - search.startTime < search.timeout && search.root.exp)
        generateChild(search, getBestChild(search.root))
        generateChild(search, getSmallChild(search.root))    
    end
end

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



function singleChild(search::Search, child::Vector{Node})
    
    while ( getTime() - search.startTime < search.timeout )
    
        for c in child
            if (c.exp)
                generateChild(search, getSmallChild(c))
                
            end
        end
                    
    end

end

function stopSearching(search::Search)
    search.cont = false
end


function generateChild(search::Search, bm::Node)
    
    if length(bm.child) > 0
        bm.exp = false
    
    else
    
        current = bm.snakes
        alphaMove = multi(search, current[1], bm.food, current, bm.hazard)
    
        bm.possibleMove = length(alphaMove)
    
        if length(alphaMove) == 0
            die(bm.snakes[1])
            bm.exp = false
            bm.score[1] = 0
        else
        
            moves = Vector{Vector{SnakeInfo}}()
            nbSnake = length(current)
            moves = merge(moves, alphaMove)
            @inbounds for i in 2:nbSnake
                moves = merge(moves, multi(search, current[i], bm.food, current, bm.hazard))
            end

            clean(moves)
            stillAlive = false
            @inbounds for move in moves
            
                if move[1].alive
                
                    addChild(bm, createNode(move, bm.food, bm.hazard))
                    stillAlive = true
                else
                
                    node = createNode(move, bm.food, bm.hazard)
                    node.score[1] = 0
                    addChild(bm, node)
                end

            
            end
        
            if stillAlive == false
                die(bm.snakes[1])
                bm.exp = false
                bm.score[1] = 0
            end

        end
    end

    1
end

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

function freeSpace(x::Int, snakes::Vector{SnakeInfo})

    free = true
    @simd for i in 1:length(snakes)
        if free
            if isSnake(snakes[i], x)
            
                free = false
        
            end
        
        end
    end

    return free
end

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

