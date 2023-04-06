module Initialise_Houses
include("./Model_DataStructures.jl")
using .Model_DataStructures
include("Initialise_Agents.jl")
include("Model_Functions.jl")

using .Model_Functions

function init_prices(agent_input, buffer, income_low, income_hi,price_coeff, base_unitprice)
    house_list = House[]
    house_buffer = House[]
    #create the housing market size with some buffer for growth
    agent_size = size(agent_input)[1]
    sim_marketsize = round(Int32, buffer * agent_size) #note the multiplier must lead to a multiple of 0.1 e.g. 1.2, 1.3...
    println("agent_size: ",agent_size)
    println("sim_marketsize: ",sim_marketsize)
    buffer_size = sim_marketsize - agent_size
    println("Income low bound in init_prices: ", income_low)   
    println("Income high bound in init_prices: ", income_hi)   
     
    for i in 1:agent_size #first we initialise the house prices based on agent incomes
        push!(house_list, House(1, 1, 0, house_price(agent_input[i].income_other,income_low, price_coeff,base_unitprice),1))
    end

    for i in 1:(buffer_size)
        push!(house_buffer, House(0, 0, 0, 1,1)) #the parameters indicate an empty buffer House unit
    end

    return house_list, house_buffer

end

export House, init_prices

end #end module