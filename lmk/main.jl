include("./Initialise_Agents.jl")
include("./Initialise_Houses.jl")

#load income data at the 23rd row of csv file, simulate 0.5% of the total number of households
#initialise a stock of Houses based on income, size of market is 1.1x number of Agents to allow for buffer for growth.
#price_coeff is the multiplier to match price function with more empirical prices
sim_Agents = Initialise_Agents.Agent[]
sim_Agents, income_low, income_hi = Initialise_Agents.populate_agents("income.csv",23, percent_agent=0.5) 
sim_Houses = Initialise_Houses.House[]
price_coeff = 0.0005; cheapest_unit = 50000; #some units may be priced below cheapest...this is more like the basic unit price for the lowest mean income.
sim_Houses = Initialise_Houses.init_prices(sim_Agents, 1.1, income_low, income_hi, price_coeff, cheapest_unit) 
println("Number of agents is: ", size(sim_Agents)[1])
println("Number of houses is: ", size(sim_Houses)[1])
println("Agent[1] and House[1] are")
display(sim_Agents[1])
display(sim_Houses[1])

