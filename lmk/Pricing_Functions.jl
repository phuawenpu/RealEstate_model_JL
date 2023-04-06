#this is where all the prices, mortgages, rents etc.. are determined

module Pricing_Functions

function house_price(income ,income_low, base_unitprice, price_coeff)
    price = (income / income_low) * income * base_unitprice * price_coeff
    #this pricing formula can be improved, so the prices are an exponential function relative to income
    return Int64(round(price))
end

export house_price

end #end module