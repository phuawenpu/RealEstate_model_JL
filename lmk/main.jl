include("./Initialise_Agents.jl")
include("./Initialise_Houses.jl")

sim_Agents = Initialise_Agents.Agent[]
sim_Agents = Initialise_Agents.populate_agents("income.csv",23, percent_agent=0.5) #load income data at the 23rd row of csv file, simulate 0.5% of the total number of households

sim_Houses = Initialise_Houses.House[]
sim_Houses = Initialise_Houses.init_prices(sim_Agents, 1.1) #initialise a stock of Houses based on income, size of market is 1.1x number of Agents to allow for buffer for growth.

println("Number of agents is: ", size(sim_Agents)[1])
println("Number of houses is: ", size(sim_Houses)[1])

#=
property_market = House[]
for i in sim_agent_population
    price = house_price(df[i,:"I"])
    push!(property_market, House(1, 1, ))
=#


