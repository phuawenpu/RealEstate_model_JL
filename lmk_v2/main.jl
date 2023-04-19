using CUDA, Plots, DelimitedFiles, BenchmarkTools, DataFrames

#inflation and mortgage interest in %
const inflation_rate = 5.5
const interest_rate = 4.7
# row number of the income dataframe to load
const row_number = 1
# ratio of the entire state's population to model
const pop_ratio = 0.0001 
#corrector for rents
const rent_coeff = 1.7
#base unit price of house
const base_unit_price = 50000
#coefficient for house prices
const price_coeff =0.0002
#spread ratio in rental probability
const rent_spread = 0.15 # 20% variance
#CUDA vector size control, memory bound:
const cuda_max_vector = 2^20
#market visibility: what portion of the market can house sellers
#"see" in prices, numbers above 20% will likely bias scoreboard to richer buyers 
market_visibility = 0.2
#sim loop number
SIM_LOOP = 1

include("./Load_Income.jl")
include("./Initialise_Data.jl")
include("./Model_Functions.jl")
# income data from singstat public database year 2022 -> row 1, year 2000 -> 23
income_df = Load_Income.load_income("./income.csv")
num_households = income_df[row_number,:"Number_Households"]
println("Total Number of Households in this dataframe row: ", num_households)
println("We simulate approximately ",pop_ratio*100, "% of them")
num_households =Int32(round((pop_ratio*num_households)/8)*8)
println("Number of households simulated: ",num_households)
if num_households >= cuda_max_vector 
    println("Number of households simulated larger than CUDA memory limit")
    return
end
# agent_list has 5 columns-> 1:income, 2:savings, 3>:expenditure, 
# 4:housing_expenditure, 5:accumulated_savings
agent_list = zeros(Int32,num_households,5);
Initialise_Data.populate_agents(income_df, row_number, agent_list)
#sort the agent_list from lowest to highest income
sort!(agent_list, dims = 1)
Initialise_Data.savings_agents(agent_list; savings_lo = 25, savings_hi = 42)
Initialise_Data.expenditure_agents(agent_list; housing_lo = 26, housing_hi = 30)

#house_list has 3 columns-> 1:house price, 2:rental price, 3:last_rent price
house_list = zeros(Int32,num_households,3)
Initialise_Data.house_list_price_from_income(income_df, row_number, agent_list, 
house_list,base_unit_price, price_coeff) 
#sort the houses_list from lowest to highest price
sort!(house_list, dims = 1)
h_size = size(house_list)[1]
a_size = size(agent_list)[1]
max_house_price = house_list[h_size]
println("Max house price: ", max_house_price)
#rentals initiated here
Initialise_Data.house_list_rental(house_list, interest_rate, inflation_rate, 
rent_coeff, max_house_price)

println("\nInitialised values: ")
println("\nagent_list has 5 columns ->
 1:monthly income, 2:monthly savings, 3:expenditure, 4:housing_expenditure, 5:accumulated_savings \n")
display(agent_list)
println("\nhouse_list has 3 columns-> 
 1:house price, 2:rental price, 3:last_rent price: \n")
display(house_list)
agent_budgets = agent_list[:,4] #this gives us the agents' rental agent_budgets
house_rentals = house_list[:,2] #this gives us the house rental prices
# run plot only for small number of households (e.g. < 1000)
if (length(house_rentals)<2049 && length(agent_budgets)<1025)
    plot(collect(1:a_size), [agent_budgets house_rentals], layout=(1,1), 
    label=["housing_expenditure" "rental_ask"], reuse=false) 
end

N = length(house_rentals) #agent_budgets assumed to be same size as house_rentals
frac_N = Int32(floor(N*market_visibility))

#= CUDA probability function
numblocks = ceil(Int, N/256)
#temporary vectors to store range of probabilities given budget and rentals
z_d = CUDA.zeros(Float16,N) 
y_d = CUDA.CuArray(house_rentals) 
=#
z_h = zeros(Float16,N)
y_h = house_rentals
# scoreboard of bids, first column is bid price, second column is agent_number
market_scoreboard = zeros(Int32, (N,3))
############### "static" initialisation above ###############
#############################################################

Threads.@threads for i in eachindex(agent_budgets)
    budget = agent_budgets[i]
    # println("agent_budget_number: ", i)
    # println("agent budget is: \$", budget)
    z_h = Model_Functions.rent_probability_CPU.(budget,y_h,rent_spread)
    #println(z_h)
    
    #turning off CUDA until there is a way to start CUDA functions in parallel processes
    #@sync @cuda threads=1024 blocks=numblocks Model_Functions.rent_probability_GPU(z_d, budget, y_d,rent_spread)
    #z_h = Array(z_d)
    choices = sortperm(z_h, rev=true); # println("sortperm for agent", i, " is ", choices')
    choices_truncated = collect(choices[1:3]) #only look at top 3 choices
    choices_others = collect(choices[4:frac_N]) #look at some of the rest of the choices
    #this first for loop gives us the bona fide buyers, whose top 3 choices fit their budget
    for choice in choices_truncated
        if house_rentals[choice] <= budget
            if market_scoreboard[choice] < budget
                market_scoreboard[choice] = budget
                market_scoreboard[N+choice]=i
            end 
        end
    end 
    #this second for loop gives us the other choices considered, so the housing sellers can 'learn' prices
    for choice in choices_others
        if budget >= market_scoreboard[choice]
            market_scoreboard[2N+choice] = budget
        end
    end

    #println("After agent ",i, " bid: ")
    #display(market_scoreboard)
end #end of choice loop
vscodedisplay(market_scoreboard)
#update the market rents
size(market_scoreboard)


if (length(house_rentals)<2049 && length(agent_budgets)<1025)
    plot(collect(1:a_size), [agent_budgets house_rentals], layout=(1,1), 
    label=["housing_expenditure" "rental_ask"], reuse=false) 
end


filename = "score_" * string(SIM_LOOP) * ".csv"
writedlm(filename, market_scoreboard, ", \t")
vscodedisplay(market_scoreboard)
SIM_LOOP += 1
