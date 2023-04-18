using CUDA, Plots, BenchmarkTools

#inflation and mortgage interest in %
const inflation_rate = 5.5
const interest_rate = 4.7
# row number of the income dataframe to load
const row_number = 1
# ratio of the entire state's population to model
const pop_ratio = 0.00001 
#corrector for rents
const rent_coeff = 1.7
#base unit price of house
const base_unit_price = 50000
#coefficient for house prices
const price_coeff =0.0002
#spread ratio in rental probability
const rent_spread = 0.2 # 20% variance
#CUDA vector size control, memory bound:
const cuda_max_vector = 2^20

include("./Load_Income.jl")
include("./Initialise_Data.jl")
include("./Model_Functions.jl")


income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households in this dataframe row: ", num_households)
println("We try to simulate ",pop_ratio*100, "% of them")
num_households =Int32(round((pop_ratio*num_households)/8)*8)
println("Actual number of households simulated: ",num_households)
if num_households >= cuda_max_vector 
    println("number of households simulated is larger than tested CUDA memory size")
    return
end
#agent_list has 5 columns-> 1:income, 2:savings, 3>:expenditure, 4:housing_expenditure, 5:accumulated_savings
agent_list = zeros(Int32,num_households,5);
Initialise_Data.populate_agents(income_df, row_number, agent_list)
#sort the agent_list from lowest to highest income
sort!(agent_list, dims = 1)
Initialise_Data.savings_agents(agent_list; savings_lo = 25, savings_hi = 42)
Initialise_Data.expenditure_agents(agent_list; housing_lo = 26, housing_hi = 30)

#house_list has 3 columns-> 1:house price, 2:rental price, 3:last_rent price
house_list = zeros(Int32,num_households,3)
Initialise_Data.house_list_price_from_income(income_df, row_number, agent_list, house_list,base_unit_price, price_coeff) 
#sort the houses_list from lowest to highest price
sort!(house_list, dims = 1)
h_size = size(house_list)[1]
a_size = size(agent_list)[1]
max_house_price = house_list[h_size]; println("Max house price: ", max_house_price)
#rentals initiated here
Initialise_Data.house_list_rental(house_list, interest_rate, inflation_rate, rent_coeff, max_house_price)

println("Initialised values: ")
println("agent_list has 5 columns -> 1:income, 2:savings, 3:expenditure, 4:housing_expenditure, 5:accumulated_savings")
display(agent_list)
println(" house_list has 3 columns-> 1:house price, 2:rental price, 3:last_rent price:")
display(house_list)

x = collect(1:a_size);
agent_budgets = agent_list[:,4] #this gives us the agents' rental agent_budgets
house_rentals = house_list[:,2] #this gives us the house rental prices
# run plot only for small number of households (e.g. < 1000)
(length(house_rentals)<2049 && length(agent_budgets)<1025) ? plot(x, [agent_budgets house_rentals], layout=(1,1), label=["housing_expenditure" "rental_ask"], reuse=false) : nothing
########## "static" initialisation above ##########
#= CPU version of rental probabilities
agent_budgets = agent_list[:,4] #this gives us the agents' rental agent_budgets
house_rentals = house_list[:,2] #this gives us the house rental prices
#step through each agents' budget, find the highest probability 
probability_cache = zeros(Float16, length(house_rentals))
probability_cache = Model_Functions.rent_probability_CPU.(agent_budgets[1], house_rentals, rent_spread)
sortperm(probability_cache)[1]
=#

N = length(agent_budgets) #agent_budgets assumed to be same size as house_rentals
z_d = CUDA.zeros(Float16,N) #vector to store range of probabilities given budget to consider
y_d = CUDA.CuArray(house_rentals)
budget = agent_budgets[1]
numblocks = ceil(Int, N/256)
@btime @sync @cuda threads = 1024 blocks=numblocks Model_Functions.rent_probability_GPU(z_d, budget, y_d,rent_spread)

z_h = Array(z_d)
@btime sortperm(z_h)[1]
sortperm(z_h)[1]


z2 = Array(z_d)
heatmap(z2)
display(z_d)


i = rand(1:length(x_d))
x_d[i]
y_d[i]
println("gpu answer is: ", z_d[i])
cpu_answer = Model_Functions.rent_probability_CPU(x_d[i], y_d[i],0.1)
println("cpu answer is: ", cpu_answer)


z_h = Array(z_d)
backend(:plotly)
p=heatmap(z)
p=heatmap(z_h)
