using DataFrames
# percent of total number of households being simulated
percent_agent = 1

struct House #each unit of property in the simulation) 
    available :: Int32 # [1 -> "vacant_no_owner", 2-> "for_sale", 3-> "for_rent", "for_sale_rent", 4->"occupied_unavailable"]
    owned_by :: Int32 # id of household who owns it  1->state landlord
    price_previous :: Int32
    price_current :: Int32
end

struct Agent #each household is the agent of the simulation
    income_other :: Int32
    income_rental :: Int32
    primary_residence :: Int32 #index to House[] array, if 1(state landlord) is homeless
    properties :: Vector{Int32} #which house ids does this agent own 1 is initial state
    total_debt :: Int32
end

include("./Load_Data.jl")
df = Load_Data.load_data("income.csv") #income data is here in deciles
vscodedisplay(df)
num_households = df[nrow(df),:"Number_Households"]
println("Number of Households: ", num_households)
sim_agent_samplesize = round(Int32, ceil(percent_agent/100 * num_households)/10)
sim_agent_population = sim_agent_samplesize * 10  #we require the agent population in multiples of ten to fit the income distribution data in deciles
sim_house_marketsize = round(Int32, sim_agent_population * 1.1) #create the housing market size with some buffer for growth

agent_list = Agent[]
no_properties = Vector{Int32}()
for i in 1:sim_agent_samplesize #generate the first decile
    min_income = df[nrow(df),:"min_income"]
    max_income = df[nrow(df),:"percentile10"] - 1
    push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
end


#housing price function:
function house_price(income ,income_low, base_price, price_coeff)
    #price_coeff = 0.0001
    price = (income / income_low) * income * base_price * price_coeff
    return Int64(round(price))
end

#=
property_market = House[]
for i in sim_agent_population
    price = house_price(df[i,:"I"])
    push!(property_market, House(1, 1, ))
=#


