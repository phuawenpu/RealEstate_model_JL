using CUDA, Distributions, BenchmarkTools
include("./Model_Functions.jl"); using .Model_Functions;
N = 2^20

x_d = CUDA.rand(N)  # a vector stored on the GPU filled with 1.0 (Float32)
y_d = CUDA.rand(N)  # a vector stored on the GPU filled with 2.0
z_d = CUDA.zeros(N)

function rent_probability_GPU(result, budget, price)
   
    index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    for i = index:stride:length(budget)
        @inbounds spread = 0.25 * budget[i]
        @inbounds  L = Normal(budget[i],spread)
        @inbounds p_fit = Float32(pdf(L, budget[i]))
        @inbounds result[i] = Float32(pdf(L, price[i]) / p_fit)
    end
    
end

numblocks = ceil(Int, N/256)

@sync @cuda threads=256 blocks=numblocks probability(z_d, x_d, y_d)

display(z_d)
i = rand(1:length(z_d))
x_d[i]
y_d[i]
println("gpu answer is: ", z_d[i])
rent_price_probability(budget = x_d[i], price = y_d[i], spread = x_d[i]*0.25)