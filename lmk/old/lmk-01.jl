using GLMakie

fig = Figure(; resolution=(700,400))

ax = Axis(fig[1, 1])

sg = SliderGrid(
    fig[1, 2],
    (label = "Lowest Group", range = 0:0.1:10, format = "{:1f}\$", startvalue = 5),
    (label = "Mid Low Group", range = 0:0.1:20, format = "{:.1f}A", startvalue = 10.2),
    (label = "Mid High Group", range = 0:0.1:30, format = "{:.1f}Ω", startvalue = 15.9),
    (label = "High Group", range = 0:0.1:30, format = "{:.1f}Ω", startvalue = 15.9),
    width = 300,
    tellheight = false)

sliderobservables = [s.value for s in sg.sliders]
bars = lift(sliderobservables...) do slvalues...
    [slvalues...]
end

barplot!(ax, bars, color = [:yellow, :orange, :red, :purple])
ylims!(ax, 0, 30)

fig