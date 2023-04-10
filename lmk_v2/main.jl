include("./Load_Income.jl")
include("./Initialise_Agents.jl")


# row number of the income dataframe to load
row_number = 23

income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households: ", num_households)
num_households = Int32(round((0.05num_households)/10)*10)
println("Total Number of Households SIMULATED: ", num_households)
agent_list = zeros(Int32,num_households,3)
Initialise_Agents.populate_agents(income_df, row_number, agent_list)
#sort the agent_list from lowest to highest income
sort!(agent_list, dims = 1)
# display(agent_list)
Initialise_Agents.savings_agents(agent_list; savings_lo = 25, savings_hi = 42)
Initialise_Agents.expenditure_agents(agent_list)
display(agent_list)

house_list = zeros(Int32,num_households)

Initialise_Agents.price_house_list(income_df, row_number, agent_list, house_list,60000, 0.0005) #base price of house and price_coeff
#sort the houses_list from lowest to highest price
sort!(house_list) #, dims = 1)

display(house_list)



