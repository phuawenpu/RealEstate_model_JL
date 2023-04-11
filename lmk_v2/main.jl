#using Plots

const N_sim_loop = Int32((30*12)/3) #30 years in periods of 3 months
#inflation and mortgage interest in %
const inflation_rate = 5.5
const interest_rate = 4.7
# row number of the income dataframe to load
const row_number = 23
# ratio of the entire state's population to model
const pop_ratio = 0.00005 #just 0.005%
#corrector for rents (so low rents are not too low)
const rent_coeff = 0.02
#base unit price of house
base_unit_price = 50000
#coefficient for house prices
const price_coeff =0.0007
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
println("display agent_list:")
display(agent_list)

#house_list has 3 columns-> 1:house price, 2:rental price, 3:last_rent price
house_list = zeros(Int32,num_households,3)
#base price of house $60000 and price_coeff 0.009
Initialise_Data.house_list_price_from_income(income_df, row_number, agent_list, house_list,base_unit_price, price_coeff) 
#sort the houses_list from lowest to highest price
sort!(house_list, dims = 1)
h_size = size(house_list)[1]
max_house_price = house_list[h_size]
Initialise_Data.house_list_rental(house_list, interest_rate, inflation_rate, max_house_price, rent_coeff)
println("display house_list:")
display(house_list)

# "static" initialisation above
# dynamic evaluation of the sim loop

println("display agent_list:")
println("1:income, 2:savings, 3:expenditure, 4:housing_expenditure, 5:accumulated_savings")
display(agent_list)

#each loop represents a 3 month period
for n in 1 : N_sim_loop 
    #first all the agents make savings to their monthly income
    agent_list[:,5] = agent_list[:,5] .+ agent_list[:,2]
    
    a_size = size(agent_list)[1]
    h_size = size(house_list)[1] #right now a_size is same as h_size, but we may develop different buyer/seller market sizes
    for i in 1:h_size
        rental_ask_price = house_list[h_size+i]
        println("House number ", i, " rental ask price: ", rental_ask_price)
        for j in 1:a_size
            agent_budget = agent_list[3a_size+j]
            prob = Model_Functions.rent_price_probability(budget = agent_budget, price = rental_ask_price, spread = rental_ask_price * rent_spread)
            println("Agent ",j, "has a budget of: ",agent_budget," has probability of rental: ", prob)
        end
    end
end #end sim loop

Model_Functions.rent_price_probability(budget = 1190, price = 1200, spread = 1200*0.06)

a_size = size(agent_list)[1]
x = collect(1:a_size)
display(agent_list)
y1 = agent_list[:,4]
y2 = house_list[:,2]
display(house_list)
plot(x, [y1 y2], layout=(2,1), label=["housing_expenditure" "rental_ask"])




