using Plots
include("./Load_Income.jl")
include("./Initialise_Agents.jl")

#inflation and mortgage interest in %
inflation_rate = 5.5
interest_rate = 4.7
# row number of the income dataframe to load
row_number = 23
# ratio of the entire state's population to model
pop_ratio = 0.01 #just 1%

income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households: ", num_households)
num_households = Int32(round((pop_ratio*num_households)/10)*10)
println("Total Number of Households SIMULATED: ", num_households)
agent_list = zeros(Int32,num_households,3)
Initialise_Agents.populate_agents(income_df, row_number, agent_list)
#sort the agent_list from lowest to highest income
sort!(agent_list, dims = 1)
# display(agent_list)
Initialise_Agents.savings_agents(agent_list; savings_lo = 25, savings_hi = 42)
Initialise_Agents.expenditure_agents(agent_list)
display(agent_list)

house_list = zeros(Int32,num_households,2)
#base price of house $60000 and price_coeff 0.0005
Initialise_Agents.house_list_price_from_income(income_df, row_number, agent_list, house_list,60000, 0.0005) 
Initialise_Agents.house_list_rental(house_list, interest_rate, inflation_rate)
#sort the houses_list from lowest to highest price
sort!(house_list, dims = 1)


x = collect(1:size(agent_list)[1])
y1 = agent_list[:,1,1]
y2 = house_list[:,1]
y3 = house_list[:,2]
plot(x, [y1], label=true)




display(house_list)


