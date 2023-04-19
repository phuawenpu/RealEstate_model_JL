#this is where all the prices, mortgages, rents etc.. are determined
module Model_Functions

using CUDA, Distributions,Random

Random.seed!(123)

#price houses based on input household monthly income
function house_price(income ,income_low, base_unitprice, price_coeff)
    #this pricing formula can be improved, so the prices are an exponential function relative to income
    price = rand(0.97:1.03) * (income / income_low) * income * base_unitprice * price_coeff
    return Int64(round(price))
end

#custom kernel function for price-budget probabilities
function rent_probability_GPU(result_vector, budget, price_vector, price_spread)
    index_x = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride_x = gridDim().x * blockDim().x

    for i = index_x:stride_x:length(price_vector)
        @inbounds if (price_vector[i] > 2*budget)
            result_vector[i]=0
            continue
        else
            @inbounds spread = price_spread * budget
            @inbounds L = Normal(budget[i],spread)
            @inbounds p_fit = Float32(pdf(L, budget))
            @inbounds result_vector[i] = Float16(pdf(L, price_vector[i]) / p_fit)
        end
    end
    return nothing
end #end rent_probability_GPU


#cpu version 
function rent_probability_CPU(budget, price, budget_spread)
    # all inputs are scalar
    # using a normal distribution to approximate consumer behaviour
    # however the hunch is consumer behaviour is more like a skewed distribution
    # i.e. given the same distance from central price, greater preference for low prices than high prices
    #=if (price > 2 * budget)
        rent_probability = 0.0
        return Float32(rent_probability)
    else=# ##optimisation for over-budget not used
        L = Normal(budget,budget_spread*budget)
        p_fit = Float32(pdf(L, budget))
        rent_probability = Float32(pdf(L, price) / p_fit)
        return rent_probability
    #end ##optimisation for low probability removed
end #end rent_probability_CPU

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

#rent price estimator is based on mortgage
function rental_monthly(house_price, interest_rate, inflation_rate, rent_coeff, max_house_price)
    # rental is simply an assumed 30 year term mortgage + inflation
    house_price_ratio = (max_house_price / house_price) 
    tenure_corrected = Int32(round((12*30)-house_price_ratio)+1)
    #println("tenure_corrected: ",tenure_corrected, " for house price: ", house_price)
    rental = mortgage_monthly(r=interest_rate, P = house_price, N=tenure_corrected) * (1+inflation_rate/100)
    # println(house_price, " rental is: ", Int32(round(rental)))
    return Int64(round(rental))
end





export house_price, rent_probability_CPU ,rent_probability_GPU, mortgage_monthly, rental_monthly

end #end module