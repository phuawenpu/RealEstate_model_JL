# percent of households being simulated
percent_agent = 1

include("./Load_Data.jl")

df = Load_Data.load_data("income.csv")
vscodedisplay(df)

#housing price function:

function house_price(income ,income_low, base_price, price_coeff)
    #price_coeff = 0.0001
    price = (income / income_low) * income * base_price * price_coeff
    return Int64(round(price))
end

