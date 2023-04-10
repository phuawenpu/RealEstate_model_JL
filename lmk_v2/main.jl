using DataFrames

row_number = 23

include("./Load_Income.jl")
include("./Initialise_Agents.jl")

income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households: ", num_households)
num_households = Int32(round((0.05*num_households)/10)*10)
println("Total Number of Households SIMULATED: ", num_households)
agent_list = zeros(Int32,num_households,3,1)
Initialise_Agents.populate_agents(income_df, row_number, agent_list)
#sort the agent_list from lowest to highest income
sort!(agent_list, dims = 1)
display(agent_list)
Initialise_Agents.savings_agents(agent_list; savings_lo = 10, savings_hi = 10)
Initialise_Agents.expenditure_agents(agent_list)
display(agent_list)




