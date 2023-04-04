include("./Initialise_Agents.jl")

sim_Agents = Initialise_Agents.Agent[]
sim_Agents = Initialise_Agents.populate_agents("income.csv",23) #load income data at the 23rd row of csv file
#= this will be a unit test to see if last 10 agents are initialised properly
for i in eachindex(sim_Agents)
    if(i > (size(sim_Agents)[1]-10))
        display(sim_Agents[i])
    end
end =#

#housing price function:
function house_price(income ,income_low, base_price, price_coeff)
    #price_coeff = 0.0001
    price = (income / income_low) * income * base_price * price_coeff
    return Int64(round(price))
end

#=
property_market = House[]
for i in sim_agent_population
    price = house_price(df[i,:"I"])
    push!(property_market, House(1, 1, ))
=#


