using WGLMakie

x = range(0, 10, length=100)
f, ax, l1 = lines(x, sin; figure=(;resolution = (400,400)))
l2 = lines!(ax, x, cos)
f

