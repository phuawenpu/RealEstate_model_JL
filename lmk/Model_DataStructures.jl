module Model_DataStructures

mutable struct Agent #each household is the agent of the simulation
    income_other :: Int32
    income_rental :: Int32
    primary_residence :: Int32 #index to House[] array, if 1(state landlord) is homeless
    properties :: Vector{Int32} #which house ids does this agent own 1 is initial state
    total_debt :: Int32
end

mutable struct House #each unit of property in the simulation) 
    available :: Int32 # 1 -> "vacant_no_owner", 2-> "for_sale", 3-> "for_rent", "for_sale_rent", 4->"occupied_unavailable" 0-> unallocated, this should be a variable size buffer
    owned_by :: Int32 # id of household who owns it  1->state landlord 0-> unallocated, this should be a variable size buffer
    price_previous :: Int32
    price_current :: Int32
    rental_price :: Int32
end

export Agent, House

end #end module