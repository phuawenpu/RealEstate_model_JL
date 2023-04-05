module Initialise_Agents
include("./Load_Income.jl")
# using DataFrames #if using nrow()


struct Agent #each household is the agent of the simulation
    income_other :: Int32
    income_rental :: Int32
    primary_residence :: Int32 #index to House[] array, if 1(state landlord) is homeless
    properties :: Vector{Int32} #which house ids does this agent own 1 is initial state
    total_debt :: Int32
end

function populate_agents(input_filename, row_number;percent_agent = 1)
    # percent of total number of households being simulated
    #load income deciles into a dataframe
    df = Load_Income.load_income(input_filename)
    Main.VSCodeServer.vscodedisplay(df)
    num_households = df[row_number,:"Number_Households"]
    println("Number of Households: ", num_households)
    sim_samplesize = round(Int32, ceil(percent_agent/100 * num_households)/10)
   
    #all the occupant agents are here
    agent_list = Agent[]
    #and the list of properties they own/rent
    no_properties = Vector{Int32}()
    for i in 1:sim_samplesize #generate the first decile
        min_income = df[row_number,:"min_income"]
        max_income = df[row_number,:"percentile15"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the second decile
        min_income = df[row_number,:"percentile15"]
        max_income = df[row_number,:"percentile25"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the third decile
        min_income = df[row_number,:"percentile25"]
        max_income = df[row_number,:"percentile35"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the fourth decile
        min_income = df[row_number,:"percentile35"]
        max_income = df[row_number,:"percentile45"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the fifth decile
        min_income = df[row_number,:"percentile55"]
        max_income = df[row_number,:"percentile65"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the sixth decile
        min_income = df[row_number,:"percentile65"]
        max_income = df[row_number,:"percentile75"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the seventh decile
        min_income = df[row_number,:"percentile75"]
        max_income = df[row_number,:"percentile85"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the eigth decile
        min_income = df[row_number,:"percentile85"]
        max_income = df[row_number,:"percentile95"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the ninth decile
        min_income = df[row_number,:"percentile95"]
        max_income = df[row_number,:"percentile100"] - 1
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    for i in 1:sim_samplesize #generate the tenth decile
        min_income = df[row_number,:"percentile100"]
        max_income = df[row_number,:"max_income"] 
        push!(agent_list, Agent(rand(min_income:max_income), 0, 1, no_properties, 0))
    end

    #= #will try to change this to a unit test of the first and last deciles 
    for i in eachindex(agent_list)
        if(i > (size(agent_list)[1]-5))
            display(agent_list[i])
        end
    end
    =#
    return agent_list
end

export Agent, populate_agents

end #end module