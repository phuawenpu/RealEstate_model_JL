include("./Initialise_Agents.jl")
include("./Initialise_Houses.jl")
include("./Model_Functions.jl")
include("./Model_DataStructures.jl")
using .Model_Functions
using .Model_DataStructures

#current inflation and interest rates % ANNUAL
inflation = 1
interest_rate = 5

#load income data at the 23rd row of csv file, simulate 0.5% of the total number of households
#initialise a stock of Houses based on income, size of market is 1.1x number of Agents to allow for buffer for growth.
#price_coeff is the multiplier to match price function with more empirical prices

sim_Agents = Initialise_Agents.Agent[]
sim_Agents, income_low, income_hi = Initialise_Agents.populate_agents("income.csv",23, percent_agent=0.5) 
#all Agents are ranked by income (sigh...)
sort!(sim_Agents, by= p -> (p.income_other))
#since House price is function of income, House [] should also be sorted
sim_Houses, sim_Houses_buffer = Initialise_Houses.House[], Initialise_Houses.House[]
price_coeff = 0.0005; cheapest_unit = 50000; #some units may be priced below cheapest
#...cheapest is more like the basic unit price for the lowest mean income.
sim_Houses, sim_Houses_buffer = Initialise_Houses.init_prices(sim_Agents, 1.1, income_low, income_hi, price_coeff, cheapest_unit) 
println("Number of agents is: ", size(sim_Agents)[1])
println("Number of houses is: ", size(sim_Houses)[1])
println("Number of buffer house market is: ", size(sim_Houses_buffer)[1])

#each agent represents a single household
#behaviour of all agents is to start to bid for rental or purchase
#rental is payable only with savings and income
#purchase is payable with above as well as mortgage

#set a rental price for each House[]
for i in eachindex(sim_Houses)
    sim_Houses[i].rental_price = Int32(round(mortgage_monthly(r=interest_rate, P=sim_Houses[i].price_current, N=(12*30)) * (1+(interest_rate/100))))
end

for i in eachindex(sim_Houses)
    println(sim_Houses[i].price_current)
end
