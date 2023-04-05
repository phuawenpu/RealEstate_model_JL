module Initialise_Houses

include("Initialise_Agents.jl")
#using .Initialise_Agents

struct House #each unit of property in the simulation) 
    available :: Int32 # [1 -> "vacant_no_owner", 2-> "for_sale", 3-> "for_rent", "for_sale_rent", 4->"occupied_unavailable"]
    owned_by :: Int32 # id of household who owns it  1->state landlord
    price_previous :: Int32
    price_current :: Int32
end


function init_prices(agent_input, buffer)
    house_list = House[]
    #create the housing market size with some buffer for growth
    sim_marketsize = round(Int32, buffer) #note the multiplier must lead to a multiple of 0.1 e.g. 1.2, 1.3...
    agent_size = size(agent_list[1])
    buffer_size = sim_marketsize - agent_size
    
    for i in 1:sim_marketsize



end

export House, init_prices

end #end module