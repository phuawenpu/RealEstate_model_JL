using DataFrames

row_number = 23

include("./Load_Income.jl")
include("./Initialise_Agents.jl")

income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households: ", num_households)
num_households = Int32(round((num_households)/10)*10)
println("Total Number of Households SIMULATED: ", num_households)
agent_list = zeros(Int32,num_households,3,1)
Initialise_Agents.populate_agents(income_df, row_number, agent_list)
#sort the agent_list from lowest to highest income
sort!(agent_list, dims = 1)
display(agent_list)
Initialise_Agents.savings_agents(agent_list; savings_lo = 25, savings_hi = 42)
Initialise_Agents.expenditure_agents(agent_list)
display(agent_list)

no_save = 0
a_size = size(agent_list)[1]
    for i in 1:a_size
        saving = agent_list[i] - agent_list[a_size + i]
        if saving < 0 
            agent_list[2* a_size + i] = 0
            no_save += 1
        else
            agent_list[2* a_size + i] = saving
        end
        
    end

    no_save / num_households

