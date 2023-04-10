module Initialise_Agents

using DataFrames


function populate_agents(df, row_number, agent_list)
    # percent of total number of households being simulated
    #load income deciles into a dataframe
    # Main.VSCodeServer.vscodedisplay(df)
    
    sim_samplesize = Int32(round(size(agent_list)[1]/10))
   
    #and the list of properties they own/rent
    
    index = 1

    for i in 1:sim_samplesize #generate the first decile
        min_income = df[row_number,:"min_income"]
        max_income = df[row_number,:"percentile15"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the second decile
        min_income = df[row_number,:"percentile15"]
        max_income = df[row_number,:"percentile25"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the third decile
        min_income = df[row_number,:"percentile25"]
        max_income = df[row_number,:"percentile35"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the fourth decile
        min_income = df[row_number,:"percentile35"]
        max_income = df[row_number,:"percentile45"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the fifth decile
        min_income = df[row_number,:"percentile55"]
        max_income = df[row_number,:"percentile65"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the sixth decile
        min_income = df[row_number,:"percentile65"]
        max_income = df[row_number,:"percentile75"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the seventh decile
        min_income = df[row_number,:"percentile75"]
        max_income = df[row_number,:"percentile85"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the eigth decile
        min_income = df[row_number,:"percentile85"]
        max_income = df[row_number,:"percentile95"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the ninth decile
        min_income = df[row_number,:"percentile95"]
        max_income = df[row_number,:"percentile100"] - 1
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end

    for i in 1:sim_samplesize #generate the tenth decile
        min_income = df[row_number,:"percentile100"]
        max_income = df[row_number,:"max_income"] 
        agent_list[index,1,1]= Int32(round(rand(min_income:max_income)))
        index += 1
    end



    return nothing
end


function savings_agents(agent_list; savings_lo, savings_hi)
    a_size = size(agent_list)[1]
    for i in 1:a_size
        agent_list[a_size + i]= Int32(round(rand(savings_lo:savings_hi)/100 * agent_list[a_size]))
        
    end
end

export populate_agents, savings_agents

end #end module