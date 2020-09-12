  struct Hazard
    hazards::Vector{UInt16}
  end
  
  #=
  This structure keep track of hazard.

  A vector for square (Int) of hazard

    For BattleRoyale,  but not fully implemented in the code.

=#
  
  function Addhazard(hazardInfo::Hazard, x::Int, y::Int)
  
    push!(hazardInfo.hazards, x*1000+y)
  end
  
  
  function hazardContain(hazardInfo::Hazard, x::UInt16)
    x in hazardInfo.hazards
  end
  
  function hazardContain(hazardInfo::Hazard, x::Int)
    x in hazardInfo.hazards
  end
  
  function inithazard(hazardInfo::Hazard,test::Array)
   
    for  i in 1:length(test)
        Addhazard(hazardInfo,test[i]["x"], test[i]["y"])
    end
  end
  
  
  function inithazard(test::Array)
   
    emptyVector = Vector{UInt16}()
    hi = hazard(emptyVector)
  
    for  i in 1:length(test)
        Addhazard(hi,test[i]["x"], test[i]["y"])
    end
  
    hi
  end