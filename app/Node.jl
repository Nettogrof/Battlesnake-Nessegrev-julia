mutable struct Node
    food::Food
    hazard::Hazard
    cc::Int
    snakes::Vector{SnakeInfo}
    child::Vector{Node}
    exp::Bool
    score::Vector{Float16}
    possibleMove::UInt8
    Node() = new()
    function Node(f,h,c,s,ch,e,sc,p) 
         new(f,h,c,s,ch,e,sc,p)
    end

end

function createNode(sn::Vector{SnakeInfo},f::Food, h::Hazard)
   
    newsn = copy(sn)
    
    child = Vector{Node}()
   # score = Vector{Float16}()

    #@inbounds for i in 1:length(sn)
     #  push!(score,0)
    #end

    #score = zeros(length(sn))
    new=Node(f,h,1,newsn,child,true,zeros(Float16,length(sn)),0)
    setScore(new)
    return new
   
end

function addChild(parent::Node, child::Node)
    push!(parent.child, child)
    parent.cc += 1
end

function getSmallChild(parent::Node)
    
    if (length(parent.child) == 0)
        return parent
    end
   
    updateScore(parent)
    child = parent.child[1]
   
    count = 6000000
  
    @inbounds for  c in parent.child
        if (c.cc < count && c.exp)
            count = c.cc
            child = c
        end
    end

    if (count == 6000000)
        parent.exp = false
    end
  

    return getSmallChild(child)
end

function getScoreRatio(parent::Node)
    totalOther = sum(parent.score) + 1
    
    #@inbounds for c in parent.score
     #   totalOther += c
    
    #end
    totalOther -= parent.score[1]

    return parent.score[1] / totalOther
end


function updateScore(parent::Node)
  
   
    if (length(parent.child) > 0 )
       
        if (parent.possibleMove == 1)
        
            parent.score = zeros(Float16,length(parent.score))

            parent.score[1]=9999
            @inbounds for current in parent.child
                parent.score[1] = current.score[1] < parent.score[1] ? current.score[1] : parent.score[1]
                @simd  for i in 2:length(parent.score)
                    @inbounds parent.score[i] = current.score[i] > parent.score[i] ? current.score[i] : parent.score[i]
                end
            end
        elseif ( parent.possibleMove > 1 && length(parent.child)> 1)
           
            head = Vector{UInt16}()
            s = Vector{Vector{Float16}}()

            for c in parent.child
               
                currenthead = c.snakes[1].body[1]
                if currenthead in head
                   
                    currentS = s[findfirst(isequal(currenthead),head)]
                    currentS[1] = c.score[1] < currentS[1] ? c.score[1] : currentS[1]
                    @inbounds for i in 2:length(c.score)
                        currentS[i] = c.score[i] > currentS[i] ? c.score[i] : currentS[i]
                    end
                    if length(parent.score) > length(c.score)
                        @inbounds for i in length(c.score):length(parent.score)
                            currentS[i] = 0.0001
                        end
                    end
                else
                  
                    push!(head,currenthead)
                   # beta = fill(-500, 9)
                    beta =  copy(c.score)
                    if length(parent.score) > length(c.score)
                        @inbounds for i in length(c.score):length(parent.score)
                            push!(beta, 0.0001)
                        end
                    end
                    push!(s,beta)
                end
            end
           
            ind = -1
            ration = -1
            @inbounds for i in 1:length(s)
                other = 0
                @inbounds for j in 2: length(s[i])
                   if s[i][j] != -500
                    other += s[i][j]
                   end 
                end
                currentration = s[i][1] / other
                if currentration > ration
                    ration = currentration
                    ind = i
                end

                
            end
           
            if ind > -1
                
                @simd for i in 1:length(s[ind])
                   
                    if s[ind][i] != -500
                        @inbounds  parent.score[i] = s[ind][i]
                    end
                end
              
                if length(s[ind]) < length(parent.score)
                    @simd  for i in length(s[ind]):length(parent.score)
                        @inbounds parent.score[i] = 0.0001
                    end
                end

            else
               
                parent.score = zeros(Float16,length(parent.score))
                for current in parent.child
                   
                    @simd  for i in 1:length(current.score)
                      
                        @inbounds  parent.score[i] += current.score[i]
                      
                    end
    
                end
              
            end


        else
           
            parent.score = zeros(Float16,length(parent.score))

            @inbounds for current in parent.child
                @simd  for i in 1:length(current.score)
                    @inbounds parent.score[i] += current.score[i]
                end

            end
        end

    end

   
    if parent.score[1] != 0
        parent.score[1] += 0.1 * parent.possibleMove
    end
    parent.cc = 1
    @inbounds for c in parent.child
        parent.cc += c.cc
    end
    
    if getScoreRatio(parent) > 30
        parent.exp = false
    end
   
    nothing
end

function setScore(parent::Node)
   
    @simd  for i in 1:length(parent.snakes)
        @inbounds parent.score[i] = parent.snakes[i].alive ? length(parent.snakes[i].body) + parent.snakes[i].health / 50  : 0
    end
    head = parent.snakes[1].body[1]
    #adjustScoreDsitance
    #adjustBorder
    adjustScoreLength(parent)
    #adjustHazards

   
    if length(parent.snakes) > 1
        nbAlive  = 0 
        for i in 1 : length(parent.snakes)
            if (parent.snakes[i].alive)
                nbAlive += 1
            end
        end

        if (nbAlive < 2)
            parent.exp = false
        end
    elseif length(parent.snakes) == 1
        parent.score[1] += 1000
    end
   
end

function adjustScoreLength(parent::Node)
    maxlength = 0 
    @inbounds for s in parent.snakes
        if length(s.body) > maxlength
            maxlength = length(s.body)
        end
    end

    @inbounds for i in 1:length(parent.snakes)
        if (length(parent.snakes[i].body) == maxlength)
            parent.score[i] += 2
        end
    end

end

function isequalroot(a::Node, b::Node)
    if !isequalFood(a.food, b.food)
        return false
    end
    for i in 1:length(a.snakes)
        if !isequalSnake(a.snakes[i], b.snakes[i])
            return false
        end
    end

    return true
end

function getBestChild(root::Node)
    if length(root.child) == 0
        return root
    end
    updateScore(root)
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
       
        if wup > choiceValue
            choiceValue = wup
            winnermove = head - 1
        end   
    end

    if (wdown != 9999.99)
      
        if wdown > choiceValue
            choiceValue = wdown
            winnermove = head + 1
        end   
    end

    if (wleft != 9999.99)
       
        if wleft > choiceValue
            choiceValue = wleft
            winnermove = head - 1000
        end   
    end

    if (wright != 9999.99)
        
        if wright > choiceValue
            choiceValue = wright
            winnermove = head + 1000
        end   
    end
  
    
    
    for i in 1:length(root.child)
        c = getScoreRatio(root.child[i])
      
        if c == choiceValue && root.child[i].snakes[1].alive && root.child[i].snakes[1].body[1] == winnermove
           
            return getBestChild(root.child[i])
        end
    end
    
    return getBestChild(root.child[1])

end