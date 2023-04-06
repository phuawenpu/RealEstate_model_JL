include("Model_Functions.jl")
using .Model_Functions
using Plots

x = range(0,10, length=1000)

index = 1
y = Int32[]
for i in collect(x)
    push!(y,mortgage_monthly(r=i, P=100000, N=12*30))
    index += 1
end

plot(x,y)