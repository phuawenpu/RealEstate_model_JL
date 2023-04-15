using CUDA
N = 2^3
x1 = CuArray{Float32}(undef,N)
x2 = CUDA.randn(Float32,N) #CuArray{Int}(undef,N)
y = CuArray{Float32}(undef, (N,3))     

fill!(x1,1.0)

numblocks = ceil(Int, N/256)

function color_matrix(result, input_1, input_2)
    index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    
    for j = index:stride:size(result)[2]
        for i = index:stride:size(result)[1]
            @cuprintln("i is: ", i, " j is: ", j)
            @inbounds result[i,j] = input_1[i] * input_2[i]
        end
    end

    return
end

@cuda blocks=numblocks color_matrix(y, x1, x2)

y
x2