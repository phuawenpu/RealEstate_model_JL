using DataFrames

row_number = 23

include("./Load_Income.jl")
include("./Initialise_Agents_v2.jl")

income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households: ", num_households)
num_households = Int32(round((0.05*num_households)/10)*10)
println("Total Number of Households SIMULATED: ", num_households)
agent_list = zeros(Int32,num_households,2)
agent_list[num_households,1] = 99
display(agent_list)
Int32(round(size(agent_list)[1]/10))


Initialise_Agents_v2.populate_agents(income_df, row_number, agent_list)

display(agent_list)

