#global agent-environment variables 
N_house = 5 #total number of houses
N_agent = 5 #total number of agents (occupants and owners)
debt_to_income = 3
interest_rate = 0.01
downpayment_ratio = 0.2
#range of random bid-ask spread
bid_ask_spread = -0.05:0.005:0.05;
#central fund test
central_bank_fund = 100_000_000

mutable struct House
    availability :: Int16 # 1: vacant_no_owner 2: for_sale 3: for_rent 4: occupied_unavailable
    owned_by :: Int32
    price_bidded :: Int32
    price_market :: Int32
end

mutable struct Agent 
    agent_id :: Int32
    income_other :: Int32
    income_rental :: Int32
    resides_at :: Int32
    properties :: Vector{Int32}
    total_debt :: Int32
end

property_market = House[]
push!(property_market, House(2, 1, 200000, 200000))
push!(property_market, House(2, 1, 200000, 200000))
push!(property_market, House(2, 1, 300000, 300000))
push!(property_market, House(2, 1, 400000, 400000))
push!(property_market, House(2, 1, 500000, 500000))

agent_list = Agent[]
null_property = Vector{Int64}() #empty variable to initialise Agent
push!(agent_list, Agent(1, 50000, 0, 1, null_property, 500000))
push!(agent_list, Agent(2, 100000, 0, 1, null_property, 100000))
push!(agent_list, Agent(3, 200000, 0, 1, null_property, 50000))
push!(agent_list, Agent(4, 200000, 0, 1, null_property, 50000))
push!(agent_list, Agent(5, 200000, 0, 1, null_property, 50000))

#bid pairing returns (highest_bid, agent_id)
function bid_pair(House, Agent) #returns the highest bid price and agent pair for each available House
    
    #each Agent submits a random bid price
    bid_price = ceil(House.price_bidded + (House.price_bidded * rand(bid_ask_spread)))
    #add current bid price to the Agent's debt and check debt_to_income
    if (bid_price + Agent.total_debt) > debt_to_income * (Agent.income_other + Agent.income_rental)
        return (0,0) 
    end 
    #exit if Agent not able to afford more debt
    if bid_price >= House.price_bidded
        House.price_bidded = bid_price
        return (bid_price, Agent.agent_id)
    end
end

for each_house in property_market
    for each_agent in agent_list
        if(bid_pair(each_house, each_agent) == (0,0))
            println("at house bid price: ", each_house.price_bidded)
            println("agent id cannot afford: ", each_agent.agent_id)
            continue
        else
            println("house bid price: ", each_house.price_bidded)
            println("agent id: ", each_agent.agent_id)
        end
    end
end
