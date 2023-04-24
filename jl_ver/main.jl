#using CUDA
using Plots, BenchmarkTools
include("./Load_Income.jl")
include("./Initialise_Data.jl")
include("./Model_Functions.jl")

#inflation and mortgage interest in %
inflation_rate = 5.5
interest_rate = 4.7
# row number of the income dataframe to load
const row_number = 1
# ratio of the entire state's population to model
const pop_ratio = 0.00006 #model sizes below 64 are not working well
#corrector for rents
const rent_coeff = 1.7
#base unit price of house
const base_unit_price = 50000
#coefficient for house prices
const price_coeff =0.0002
#spread ratio in rental probability
const rent_spread = 0.2 # this is variance of the probability func.
#CUDA vector size control, memory bound:
const cuda_max_vector = 2^20
const tenure_typical = 6 #6 months being the typical tenure
#market visibility: what portion of the market can house sellers
#"see" in prices, numbers above 20% will likely bias scoreboard to richer buyers 
market_visibility = 0.19


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

#house_list has 3 columns-> 1:house price, 2:rental price, 3:rented_by
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
 1:house price, 2:rental price, 3:rented_by \n")
display(house_list)
agent_budgets = agent_list[:,4] #this gives us the agents' rental agent_budgets
agent_budgets = hcat(agent_budgets,zeros(Int32,length(agent_budgets))) #append a column of zeros as rental tenure
house_rentals = house_list[:,2] #this gives us the house rental prices
house_rentals = hcat(house_rentals,zeros(Int32,length(house_rentals))) #append a column of zeros as agent tenant identities

N = size(house_rentals)[1] #agent_budgets assumed to be same size as house_rentals
visible_N = Int32(floor(N*market_visibility))
# first plot of rental prices against agent budgets
# run plot only for small number of households (e.g. < 1000)
if (N<4000)
    plot(collect(1:a_size), [agent_budgets[:,1] house_rentals[:,1]], layout=(1,1), 
    label=["housing_expenditure_initial" "rental_ask_initial"], reuse=false, size = (800,800)) 
end

#= setup for CUDA probability function
numblocks = ceil(Int, N/256)
#temporary vectors to store range of probabilities given budget and rentals
z_d = CUDA.zeros(Float16,N) 
y_d = CUDA.CuArray(house_rentals) 
=#
datadump = Any[] #for saving of each loop data

#sim loop number
SIM_LOOP = 1

anim = @animate for i in 1:10

########## "static" initialisation above ##########
# reason for renaming to z_h z_d is because of CUDA / non CUDA code
z_h = zeros(Float32,N)
y_h = house_rentals[:,1]
# scoreboard of bids, first column is bid price, second column is agent_number
market_scoreboard = zeros(Int32, (N,3))
#Model_Functions.saveCSV("budgets_initialisation.csv",agent_budgets)
#Model_Functions.saveCSV("house_rentals_initialisation.csv",house_rentals)

#only agent_budgets and house_rentals are dynamic variables from here onwards

# first critical decision loop, for each agent, discover their price preference,
# sort the preferences, top 2 preferred housings receives the highest bid
#multithreading isn't fair if richer bid ahead of poorer, but so is real life
Threads.@threads for i in eachindex(agent_budgets[:,1]) 
    budget = agent_budgets[i]
    # println("agent_budget_number: ", i); println("agent budget is: \$", budget)
    z_h = Model_Functions.rent_probability_CPU.(budget,y_h,rent_spread)
    #disable CUDA until there is a way to start CUDA functions in parallel processes
    #@sync @cuda threads=1024 blocks=numblocks Model_Functions.rent_probability_GPU(z_d, budget, y_d,rent_spread)
    #z_h = Array(z_d)
    choices = sortperm(z_h, rev=true); # println("sortperm for agent", i, " is ", choices')
    choices_truncated = collect(choices[1:2]) #only look at top 3 choices
    choices_others = collect(choices[3:visible_N]) #look at some of the rest of the choices
    #this first for loop gives us the bona fide buyers, whose top 2 choices fit their budget
    for choice in choices_truncated
        if house_rentals[choice] <= budget
            if market_scoreboard[choice] < budget
                market_scoreboard[choice] = budget
                market_scoreboard[N+choice]=i
            end 
        end
    end 
    #this second for loop gives us the other choices considered, so the scoreboard can 'learn' prices
    #the scoreboard third column of "learned" prices varies with market visibility etc.
    for choice in choices_others
        if budget >= market_scoreboard[choice]
            market_scoreboard[2N+choice] = budget
        end
    end
end #end of choice loop

#Model_Functions.saveCSV("market_scoreboard_FIRSTRUN.csv",market_scoreboard)

#old market mean for info
println("Previous mean rental: \$", Int32(round(sum(house_rentals[:,1])/N)))
#k1 is to capture all the housing which has willing bidders
k1 = map((x,y)-> (x!=0) ? y : 0, market_scoreboard[:,1], house_rentals[:,1])
size_k1 = sum( map((x)->(x!=0) ? 1 : 0, k1) )
#and using k1 to re-calculate the realistic market mean bid price
new_market_mean = Int32(round(sum(k1)/size_k1))
println("New mean of allocated market: \$", new_market_mean)

#allocate the bidders their housing
last_bidder = 0
for i in eachindex(market_scoreboard[:,2])
    a_index = N+i
    bidder = market_scoreboard[a_index]
    if bidder!=0 && bidder==last_bidder
        continue
    else
        if bidder!=0
            house_rentals[a_index] = bidder #allocate the bidder to the rental
            house_rentals[i] = market_scoreboard[i]
            tenure = agent_budgets[a_index] #read the tenure from the agent_budget record, if it is 0, reset it
            (tenure==0) ? agent_budgets[a_index] = tenure_typical : agent_budgets[a_index] = tenure - 1
        end
    end
    last_bidder = bidder
end

#Model_Functions.saveCSV("house_rentals_FIRSTRUN.csv",house_rentals)
#Model_Functions.saveCSV("agent_budgets_FIRSTRUN.csv",agent_budgets)
#account for homeless (who or how many or both?)

for i in eachindex(agent_budgets[:,1])
    a_index = N+i
    budget = agent_budgets[i] 
    if agent_budgets[a_index] == 0
        if (budget > new_market_mean)
            println("agent_budget used to be", agent_budgets[i])
            println("to be reduced")
            adjustment = rand(-15:0.5:0)/100 * budget #reduce somewhere up to 15% lower 
        else
            adjustment = rand(0:0.5:15)/100 * budget #else increase up to 15%
        end
        budget += adjustment; 
        agent_budgets[i] = Int32(round(budget))
    end
end
#vscodedisplay(agent_budgets) ##


#adjust the rental prices across town

if (N<4000) # run plot only for small number of households (e.g. < 1000)
    plot!(collect(1:a_size), [agent_budgets[:,1] house_rentals[:,1]], layout=(1,1), 
    label=["housing_expenditure" "rental_ask"], reuse=true, size = (800,800)) 
end

datadump = hcat(house_rentals,agent_budgets)
#filename = "market_" * string(SIM_LOOP) * ".csv"
#Model_Functions.saveCSV(filename, datadump)

end

gif(anim, "gameofrent.gif"; fps = 5)
