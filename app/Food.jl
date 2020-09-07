struct Food
  foods::Vector{UInt16}
end



function AddFood(foodInfo::Food, x::Int, y::Int)

  push!(foodInfo.foods, x*1000+y)
end

function foodContain(foodInfo::Food,x::Int)
  x in foodInfo.foods
end



function initFood(foodInfo::Food,test::Array)
 
  for  i in 1:length(test)
      AddFood(foodInfo,test[i]["x"], test[i]["y"])
  end
end


function initFood(test::Array)
 
  
  fi = Food(Vector{UInt16}())

  for  i in 1:length(test)
      AddFood(fi,test[i]["x"], test[i]["y"])
  end

  fi
end
function isequalFood(a::Food, b::Food)

  return a .== b

end
