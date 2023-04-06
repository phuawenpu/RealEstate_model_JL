module Initialise_Houses

include("Initialise_Agents.jl")
include("Pricing_Functions.jl")

using .Pricing_Functions

struct House #each unit of property in the simulation) 
    available :: Int32 # 1 -> "vacant_no_owner", 2-> "for_sale", 3-> "for_rent", "for_sale_rent", 4->"occupied_unavailable" 0-> unallocated, this should be a variable size buffer
    owned_by :: Int32 # id of household who owns it  1->state landlord 0-> unallocated, this should be a variable size buffer
    price_previous :: Int32
    price_current :: Int32
end

function init_prices(agent_input, buffer, income_low, income_hi,price_coeff, base_unitprice)
    house_list = House[]
    #create the housing market size with some buffer for growth
    agent_size = size(agent_input)[1]
    sim_marketsize = round(Int32, buffer * agent_size) #note the multiplier must lead to a multiple of 0.1 e.g. 1.2, 1.3...
    println("agent_size: ",agent_size)
    println("sim_marketsize: ",sim_marketsize)
    buffer_size = sim_marketsize - agent_size
    println("Income low bound in init_prices: ", income_low)   
    println("Income high bound in init_prices: ", income_hi)   
     
    for i in 1:agent_size #first we initialise the house prices based on agent incomes
        push!(house_list, House(1, 1, 0, house_price(agent_input[i].income_other,income_low, price_coeff,base_unitprice)))
    end

    for i in 1:(buffer_size)
        push!(house_list, House(0, 0, 0, 1)) #the parameters indicate an empty buffer House unit
    end

    return house_list

end

export House, init_prices

end #end module