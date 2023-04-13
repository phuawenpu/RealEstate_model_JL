using CUDA, Distributions, Plots
include("./Model_Functions.jl")
N = 2^26


x_d = CUDA.fill(Float32(0.5),N)
y_d = CUDA.rand(Float32,N)  
z_d = CUDA.zeros(Float32,N)

function rent_probability_GPU(result, budget, price, price_spread)
    #price is a scalar quantity!
    index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    for i = index:stride:length(budget)
        @inbounds spread = price_spread * budget[i]
        @inbounds  L = Normal(budget[i],spread)
        @inbounds p_fit = Float32(pdf(L, budget[i]))
        @inbounds result[i] = Float32(pdf(L, price) / p_fit)
    end
    
end

numblocks = ceil(Int, N/256)


@cuda threads=1024 blocks=numblocks rent_probability_GPU(z_d, x_d, y_d,0.1)
z_d

x = Array(x_d)
y = Array(y_d)
z = zeros(length(z_d))

for a in 1:N
    z[a] = Model_Functions.rent_probability_CPU(x[a],y[a],0.1)
end
z

z_gpu_result = Array(z_d)
backend(:plotly)
gpu_heatmap = heatmap(z_gpu_result)
cpu_heatmap = heatmap(z)
both_heatmaps = [gpu_heatmap, cpu_heatmap]
p = plot(both_heatmaps..., layout = (2,1), aspect_ratio = :equal)



display(z_d)
i = rand(1:length(x_d))
x_d[i]
y_d[i]
println("gpu answer is: ", z_d[i])
cpu_answer = Model_Functions.rent_probability_CPU(x_d[i], y_d[i],0.1)
println("cpu answer is: ", cpu_answer)

z_h = Array(z_d)
using Plots
backend(:plotly)
p=heatmap(z_h)
gui(p)