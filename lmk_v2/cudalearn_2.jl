using CUDA, Plots
N = 2^4
x1 = CUDA.randn(Float32,N)
x2 = CUDA.randn(Float32,N) #CuArray{Int}(undef,N)
y = CuArray{Float32}(undef, (N,3))     

fill!(x1,1.0)

numblocks = ceil(Int, N/256)

function color_matrix(result, input_1, input_2)
    index_x = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride_x = gridDim().x * blockDim().x
    
    index_y = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    stride_y = gridDim().y * blockDim().y
    
    for j = index_y:stride_y:size(result)[2]
        for i = index_x:stride_x:size(result)[1]
            #@cuprintln("i is: ", i, " j is: ", j)
            @inbounds result[i,j] = Float32(input_1[i] * input_2[j])
        end
    end

    return
end

@cuda blocks=numblocks color_matrix(y, x1, x2)
y
