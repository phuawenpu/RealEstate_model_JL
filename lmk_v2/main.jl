#using CUDA
using Plots

const N_sim_loop = Int32((30*12)/3) #30 years, each timestep = 3 months
#inflation and mortgage interest in %
const inflation_rate = 5.5
const interest_rate = 4.7
# row number of the income dataframe to load
const row_number = 23
# ratio of the entire state's population to model
const pop_ratio = 0.00005 #just 0.005%
#corrector for rents (so low rents are not too low)
rent_coeff = 0.1
#base unit price of house
const base_unit_price = 60000
#coefficient for house prices
price_coeff =0.0005
#spread ratio in rental probability
const rent_spread = 0.08 # 8% of variance

include("./Load_Income.jl")
include("./Initialise_Data.jl")
include("./Model_Functions.jl")


income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households: ", num_households)
num_households = Int32(round((pop_ratio*num_households)/10)*10)
println("Total Number of Households SIMULATED: ", num_households)
#agent_list has 5 columns-> 1:income, 2:savings, 3:expenditure, 4:housing_expenditure, 5:accumulated_savings
agent_list = zeros(Int32,num_households,5)
Initialise_Data.populate_agents(income_df, row_number, agent_list)
#sort the agent_list from lowest to highest income
sort!(agent_list, dims = 1)
Initialise_Data.savings_agents(agent_list; savings_lo = 25, savings_hi = 42)
Initialise_Data.expenditure_agents(agent_list; housing_lo = 26, housing_hi = 29)

#house_list has 3 columns-> 1:house price, 2:rental price, 3:last_rent price
house_list = zeros(Int32,num_households,3)
Initialise_Data.house_list_price_from_income(income_df, row_number, agent_list, house_list,base_unit_price, price_coeff) 
#sort the houses_list from lowest to highest price
sort!(house_list, dims = 1)
h_size = size(house_list)[1]
a_size = size(agent_list)[1]
max_house_price = house_list[h_size]; println("Max house price: ", max_house_price)
Initialise_Data.house_list_rental(house_list, interest_rate, inflation_rate, rent_coeff)

println("display agent_list:")
println("1:income, 2:savings, 3:expenditure, 4:housing_expenditure, 5:accumulated_savings")
display(agent_list)
println(" house_list has 3 columns-> 1:house price, 2:rental price, 3:last_rent price:")
display(house_list)

# "static" initialisation above
# dynamic evaluation of the sim loop

agent_budgets = agent_list[:,4] #this gives us the agents' rental agent_budgets
house_rentals = house_list[:,2] #this gives us the house rental prices
###################

x = collect(1:a_size);
plot(x, [agent_budgets house_rentals], layout=(1,1), label=["housing_expenditure" "rental_ask"])


N = 2^20

x_d = CUDA.rand(N)  # a vector stored on the GPU filled with 1.0 (Float32)
y_d = CUDA.rand(N)  # a vector stored on the GPU filled with 2.0
z_d = CUDA.zeros(N)


numblocks = ceil(Int, N/256)

@sync @cuda threads=256 blocks=numblocks probability(z_d, x_d, y_d)


