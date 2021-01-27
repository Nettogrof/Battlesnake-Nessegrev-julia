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

#=
    This structure represent each node of the tree search,  contain food info, hazard info
    cc is the number of child and sub-child under this node
    exp :  does this node need to be expand
    score: vector score for snake   score[1] is the score of this snake
    possiblemove is howw many possible this snake can do  (max 4 at the start of the game,  usually 3 or less)

=#

function createNode(sn::Vector{SnakeInfo},f::Food, h::Hazard)
   
    newsn = copy(sn)
    
    child = Vector{Node}()
    new=Node(f,h,1,newsn,child,true,zeros(Float16,length(sn)),0)
    setScore(new)
    return new
   
end


function addChild(parent::Node, child::Node)
    push!(parent.child, child)
    parent.cc += 1
end


function addChildDebug(parent::Node, child::Node)
    println("addchild")
    push!(parent.child, child)
    parent.cc += 1
end


#=
    Get the child or sub-child with the lowest cc,  so the smaller sub-tree

=#
function getSmallChild(parent::Node)
    
    if (length(parent.child) == 0)
        return parent  #return self if no child
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


#=
    Get the score ratio
    This snake score divide by other snakes score
=#
function getScoreRatio(parent::Node)
    return parent.score[1] / (sum(parent.score) + 1 - parent.score[1])
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

#=
    Set Score of a leaf node
    Currently is mostly the score equal the length of the snake + length

    addition score if the only snake alive,  or if the snake is the longest.

=#

function setScore(parent::Node)
   #= if (false)
        @simd  for i in 1:length(parent.snakes)
            @inbounds parent.score[i] = parent.snakes[i].alive ? length(parent.snakes[i].body) + parent.snakes[i].health / 50  : 0
        end
        head = parent.snakes[1].body[1]
        #adjustScoreDsitance
        #adjustBorder
        #adjustScoreLength(parent)
        #adjustHazards(parent)
        if (length(parent.snakes) < 4)
            
            adjustGroundControl(parent)
        
        end
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
    else=#  #snack-a-tron
        @simd  for i in 1:length(parent.snakes)
            @inbounds parent.score[i] = 0
        end
        adjustGroundControl(parent)
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

#=
    Add score if the longest snake
=#

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

function adjustHazards(parent::Node)
   
    @inbounds for i in 1:length(parent.snakes)
        if hazardContain(parent.hazard , parent.snakes[i].body[1] )
           parent.score[i] -= 0.5
        end
    end
end


#= 
add Score based on "Area/ground control"

=#
function adjustGroundControl(parent::Node)
   
    h = 19
    w = 19
   
    board =  zeros(Int16, h, w)
    
  
    for sn in parent.snakes
        @simd for square in sn.body
            @inbounds  board[(square ÷ 1000)+1, (square % 1000)+1] = -99
        end
    end
  
    negboard = deepcopy(board)

    board[ (parent.snakes[1].body[1] ÷ 1000)+1, (parent.snakes[1].body[1] % 1000)+1] = 0
    
    floodpos(board, parent.snakes[1].body[1] ÷ 1000, parent.snakes[1].body[1] % 1000 , 35,h,w)
    
    for i in 2:length(parent.snakes)
        negboard[(parent.snakes[i].body[1] ÷ 1000)+1 ,(parent.snakes[i].body[1] % 1000)+1] = 0
        floodneg(negboard, parent.snakes[i].body[1] ÷ 1000, parent.snakes[i].body[1] % 1000  , -35,h,w)
    end
   
  
    final= board + negboard

    cp =0
    cn =0
    @simd for i in 1:w
        @simd for j in 1:h
                if (final[i,j]>0)
                   cp+=1
              elseif (final[i,j]<0 && final[i,j] != -99)
                 cn+=1
              end
          end
    end
   
    parent.score[1] += 2 * (cp / (h + w)) 
    @simd for i in 2:length(parent.snakes)
        parent.score[i] += 2 * (cn / (h+w)) 
    end
    
end



#=
    Flood positif value on board
=#
function floodpos(board::Array{Int16,2}, x::Integer, y::Integer , value::Int64 , h::Int64 , w::Int64)
   

    if board[(x)+1, (y)+1] >= 0 && board[(x)+1, (y)+1] < value
        board[(x)+1, (y)+1] = Int16(value)
        if value > 1
            value -= 1
            if (y < h - 2 )
                floodnorthpos(board, x , y +1 ,value,h,w);
            end

            if (x < w - 2 )
                floodeastpos(board, x + 1 ,y  ,value,h,w);
            end

            if (y >0 )
                floodsouthpos(board, x , y - 1  ,value,h,w);
            end

            if (x >0 )
                floodwestpos(board , x - 1,y  ,value,h,w);
            end
        end
    end

  
end



#=
    Flood north positif value on board
=#
function floodnorthpos(board::Array{Int16,2}, x::Integer, y::Integer , value::Int64 , h::Int64 , w::Int64)
   

    if board[(x)+1, (y)+1] >= 0 && board[(x)+1, (y)+1] < value
        board[(x)+1, (y)+1] = Int16(value)
        if value > 1
            value -= 1
            if (y < h - 2 )
                floodnorthpos(board, x , y +1 ,value,h,w);
            end

            if (x < w - 2 )
                floodeastpos(board, x + 1 ,y  ,value,h,w);
            end

            if (x >0 )
                floodwestpos(board , x - 1,y  ,value,h,w);
            end
        end
    end

  
end


#=
    Flood south positif value on board
=#
function floodsouthpos(board::Array{Int16,2}, x::Integer, y::Integer , value::Int64 , h::Int64 , w::Int64)
   

    if board[(x)+1, (y)+1] >= 0 && board[(x)+1, (y)+1] < value
        board[(x)+1, (y)+1] = Int16(value)
        if value > 1
            value -= 1
           
            if (x < w - 2 )
                floodeastpos(board, x + 1 ,y  ,value,h,w);
            end

            if (y >0 )
                floodsouthpos(board, x , y - 1  ,value,h,w);
            end

            if (x >0 )
                floodwestpos(board , x - 1,y  ,value,h,w);
            end
        end
    end

  
end



#=
    Flood east positif value on board
=#
function floodeastpos(board::Array{Int16,2}, x::Integer, y::Integer , value::Int64 , h::Int64 , w::Int64)
   

    if board[(x)+1, (y)+1] >= 0 && board[(x)+1, (y)+1] < value
        board[(x)+1, (y)+1] = Int16(value)
        if value > 1
            value -= 1
            if (y < h - 2 )
                floodnorthpos(board, x , y +1 ,value,h,w);
            end

            if (x < w - 2 )
                floodeastpos(board, x + 1 ,y  ,value,h,w);
            end

            if (y >0 )
                floodsouthpos(board, x , y - 1  ,value,h,w);
            end

            
        end
    end

  
end



#=
    Flood west positif value on board
=#
function floodwestpos(board::Array{Int16,2}, x::Integer, y::Integer , value::Int64 , h::Int64 , w::Int64)
   

    if board[(x)+1, (y)+1] >= 0 && board[(x)+1, (y)+1] < value
        board[(x)+1, (y)+1] = Int16(value)
        if value > 1
            value -= 1
            if (y < h - 2 )
                floodnorthpos(board, x , y +1 ,value,h,w);
            end

            if (y >0 )
                floodsouthpos(board, x , y - 1  ,value,h,w);
            end

            if (x >0 )
                floodwestpos(board , x - 1,y  ,value,h,w);
            end
        end
    end

  
end


#=
    Flood negatif value on board
=#
function floodneg(board::Array{Int16,2},  x::Integer, y::Integer  , value::Int64 , h::Int64 , w::Int64)

    if  board[(x)+1, (y)+1] > value
        board[(x)+1, (y)+1] = Int16(value)
        if value < -1
            value += 1
          
            if (y < h - 1 )
                floodnegnorth(board,x,y+1  ,value,h,w);
            end

            if (x < w - 1 )
                floodnegeast(board,x+1,y  ,value,h,w);
            end

            if (y >0 )
                floodnegsouth(board,x,y-1  ,value,h,w);
            end

            if (x >0 )
                floodnegwest(board,x-1,y  ,value,h,w);
            end
        end
    end
end

 
#=
    Flood negatif value on board
=#
function floodnegnorth(board::Array{Int16,2},  x::Integer, y::Integer  , value::Int64 , h::Int64 , w::Int64)

    if  board[(x)+1, (y)+1] > value
        board[(x)+1, (y)+1] = Int16(value)
        if value < -1
            value += 1
          
            
            if (y < h - 1 )
                floodnegnorth(board,x,y+1  ,value,h,w);
            end

            if (x < w - 1 )
                floodnegeast(board,x+1,y  ,value,h,w);
            end

           

            if (x >0 )
                floodnegwest(board,x-1,y  ,value,h,w);
            end
        end
    end
end


#=
    Flood negatif value on board
=#
function floodnegsouth(board::Array{Int16,2},  x::Integer, y::Integer  , value::Int64 , h::Int64 , w::Int64)

    if  board[(x)+1, (y)+1] > value
        board[(x)+1, (y)+1] = Int16(value)
        if value < -1
            value += 1
          
           
           

            if (x < w - 1 )
                floodnegeast(board,x+1,y  ,value,h,w);
            end

            if (y >0 )
                floodnegsouth(board,x,y-1  ,value,h,w);
            end

            if (x >0 )
                floodnegwest(board,x-1,y  ,value,h,w);
            end
        end
    end
end
  
#=
    Flood negatif value on board
=#
function floodnegwest(board::Array{Int16,2},  x::Integer, y::Integer  , value::Int64 , h::Int64 , w::Int64)

    if  board[(x)+1, (y)+1] > value
        board[(x)+1, (y)+1] = Int16(value)
        if value < -1
            value += 1
          
           
            if (y < h - 1 )
                floodnegnorth(board,x,y+1  ,value,h,w);
            end

           
            if (x >0 )
                floodnegwest(board,x-1,y  ,value,h,w);
            end

            if (y >0 )
                floodnegsouth(board,x,y-1  ,value,h,w);
            end

            
        end
    end
end

#=
    Flood negatif value on board
=#
function floodnegeast(board::Array{Int16,2},  x::Integer, y::Integer  , value::Int64 , h::Int64 , w::Int64)

    if  board[(x)+1, (y)+1] > value
        board[(x)+1, (y)+1] = Int16(value)
        if value < -1
            value += 1
          
           
            if (y < h - 1 )
                floodnegnorth(board,x,y+1  ,value,h,w);
            end

            if (x < w - 1 )
                floodnegeast(board,x+1,y  ,value,h,w);
            end

            if (y >0 )
                floodnegsouth(board,x,y-1  ,value,h,w);
            end

            
        end
    end
end
#=
    Return true if both node are equals

        Use in the function to reuse previous search tree
=#
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


#=
    Get the child or sub-child with the best score ratio for this snake

=#
function getBestChild(root::Node)
    if length(root.child) == 0  || !root.exp
        return root  #Return this leaf if no child
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