#this is where all the prices, mortgages, rents etc.. are determined
module Model_Functions

using CUDA, Distributions

#price houses based on input household monthly income
function house_price(income ,income_low, base_unitprice, price_coeff)
    #this pricing formula can be improved, so the prices are an exponential function relative to income
    price = rand(0.95:1.05) * (income / income_low) * income * base_unitprice * price_coeff
    return Int64(round(price))
end

#custom kernel function for price-budget probabilities
function rent_probability_GPU(result, budget, price, price_spread)
    index_x = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride_x = gridDim().x * blockDim().x

    for j = index_x:stride_x:size(result)[2]
        for i = index_x:stride_x:size(result)[1]
            @inbounds spread = price_spread * budget[i]
            @inbounds L = Normal(budget[i],spread)
            @inbounds p_fit = Float32(pdf(L, budget[i]))
            @inbounds result[i,j] = Float32(pdf(L, price[i]) / p_fit)
        end
    end
    
    return
end


#cpu version for results TESTING purposes only
function rent_probability_CPU(budget, price, budget_spread)
    # all inputs are scalar
    # using a normal distribution to approximate consumer behaviour
    # however the hunch is consumer behaviour is more like a skewed distribution
    # i.e. given the same distance from central price, greater preference for low prices than high prices
    L = Normal(budget,budget_spread*budget)
    p_fit = Float32(pdf(L, budget))
    rent_probability = Float32(pdf(L, price) / p_fit)
    return Float16(rent_probability)
end 


#monthly mortgage payment given ANNUAL % interest rate, principal owed, 
# term i.e. number of repayment months
function mortgage_monthly(;r, P, N)

    if r ≈ 0.0 #in interest free world, just principle / term
        return Int32(round(P/N))
    else
        r = r / 100 / 12
        c = r*P / 1-(1+r)^(-N)
    return Int32(round(c))
    end
end


# rent price estimator is based on mortgage
function rental_monthly(house_price, interest_rate, inflation_rate, rent_coeff, max_house_price)
    # rental is simply an assumed 30 year term mortgage + inflation
    house_price_ratio = max_house_price / house_price
    tenure_corrected = Int32(round((12*30)-house_price_ratio)+1)
    if house_price_ratio < 20 tenure_corrected = tenure_corrected+Int32(round(house_price_ratio*15)) end
    rental = mortgage_monthly(r=interest_rate, P = house_price, N=tenure_corrected) * (1+inflation_rate/100) * rent_coeff
    # println(house_price, " rental is: ", Int32(round(rental)))
    return Int64(round(rental))
end


export house_price, rent_probability_CPU ,rent_probability_GPU, mortgage_monthly, rental_monthly

end #end module