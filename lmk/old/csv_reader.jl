using DataFrames, CSV

income_df = DataFrame(CSV.File("IncomeDistribution.csv"))

first(income_df, 3)

typeof(income_df[1, :HouseholdDebt_ratio_of_GDP])