using CUDA, Plots

N_sim_loop = Int32((30*12)/3) #30 years, each timestep = 3 months
#inflation and mortgage interest in %
inflation_rate = 5.5
interest_rate = 4.7
# row number of the income dataframe to load
row_number = 23
# ratio of the entire state's population to model
pop_ratio = 0.00004 
#corrector for rents
rent_coeff = 0.89
#base unit price of house
base_unit_price = 65000
#coefficient for house prices
price_coeff =0.0005
#spread in rental acceptance probabilityusing Plots

N_sim_loop = Int32((30*12)/3) #30 years, each timestep = 3 months
#inflation and mortgage interest in %
inflation_rate = 5.5
interest_rate = 4.7
# row number of the income dataframe to load
row_number = 23
# ratio of the entire state's population to model
pop_ratio = 0.00004 #just 0.004%
#corrector for rents
rent_coeff = 0.4
#base unit price of house
base_unit_price = 65000
#coefficient for house prices
price_coeff =0.0005
#spread ratio in rental probability
rent_spread = 0.25 # 8% of variance
#CUDA vector size control, memory bound:
cuda_max_vector = 2^18

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
agent_list = zeros(Int32,num_households,5)
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

println("display agent_list:")
println("1:income, 2:savings, 3:expenditure, 4:housing_expenditure, 5:accumulated_savings")
display(agent_list)
println(" house_list has 3 columns-> 1:house price, 2:rental price, 3:last_rent price:")
display(house_list)

x = collect(1:a_size);
agent_budgets = agent_list[:,4] #this gives us the agents' rental agent_budgets
house_rentals = house_list[:,2] #this gives us the house rental prices
# run plot only for small number of households (e.g. < 1000)
(length(house_rentals)<1025 && length(agent_budgets)<1025) ? plot(x, [agent_budgets house_rentals], layout=(1,1), label=["housing_expenditure" "rental_ask"], reuse=false) : nothing
# "static" initialisation above

z = zeros(length(house_rentals))
for i in eachindex(agent_budgets)
    for j in eachindex(agent_budgets)
        z[i,j] = Model_Functions.rent_probability_CPU(agent_budgets[j],house_rentals[i], rent_spread)
    end
end
(length(house_rentals) < 1025) ? heatmap(z, reuse=false) : nothing




# dynamic evaluation of the sim loop


N = length(agent_budgets) #agent_budgets assumed to be same size as house_rentals
x_d = CUDA.CuArray(house_rentals)
y_d = CUDA.CuArray(agent_budgets)
z_d = CUDA.zeros(Float16,(N,N)) #vector to store range of probabilities given budget to consider

numblocks = ceil(Int, N/256)

@cuda blocks=numblocks Model_Functions.rent_probability_GPU(z_d, x_d, y_d,rent_spread)

z_d

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
