#this is where all the prices, mortgages, rents etc.. are determined
module Model_Functions

using Distributions

#price houses based on input household monthly income
function house_price(income ,income_low, base_unitprice, price_coeff)
    #this pricing formula can be improved, so the prices are an exponential function relative to income
    price = rand(0.95:1.05) * (income / income_low) * income * base_unitprice * price_coeff
    return Int64(round(price))
end

#probability that a house will be rented based on budget
function rent_price_probability(budget, price, spread)
    # using a normal distribution to approximate consumer behaviour
    # however the hunch is consumer behaviour is more like a skewed distribution
    # i.e. given the same distance from central price, greater preference for low prices than high prices
    L = Normal(budget,spread)
    p_fit = Float32(pdf(L, budget))
    rent_probability = Float32(pdf(L, price) / p_fit)
    println(rent_probability)
    cutoff = 0.005
    if rent_probability <= cutoff
        return Float32(0)
    else return rent_probability
    end
end

#monthly mortgage payment given ANNUAL % interest rate, principal owed, 
# term i.e. number of repayment months
function mortgage_monthly(;r, P, N)

    if r ≈ 0.0 #in interest free world, just principle / term
        return Int32(round(P/N))
    else
        r = r / 100 / 12
        c = Int32(round(r*P / 1-(1+r)^(-N)))
    return c
    end
end


# rent price estimator is based on mortgage
function rental_monthly(house_price, interest_rate, inflation_rate)
    # rental is simply an assumed 30 year term mortgage + inflation
    rental = mortgage_monthly(r=interest_rate, P = house_price, N=(12*30)) * (1+inflation_rate/100)
    return Int64(round(rental))
end


export house_price, rent_price_probability, mortgage_monthly, rental_monthly

end #end module