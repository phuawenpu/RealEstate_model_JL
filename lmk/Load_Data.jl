module Load_Data

using DelimitedFiles, DataFrames

function load_data(filename)
    #load income data in deciles and extrapolate lower and upper bounds 
    mat, head = readdlm(filename, ',', Int32, header=true)
    df = DataFrame(mat, vec(head))
    #extrapolate lower and upper bounds
    df.min_income .= Int32.(df."1st" - round.((df."2nd" - df."1st")/2)) #extrapolate min point of mean income
    df.percentile10 .= Int32.(df."1st") 
    # df.percentile15 .= Int32.(round.((df."2nd"- df."1st")/2) + df."1st") #extrapolate midpoint between deciles of income
    df.percentile20 .= Int32.(df."2nd") #rename all the deciles to percentiles, to display in increasing order in dataframe
    # df.percentile25 .= Int32.(round.((df."3rd"- df."2nd")/2) + df."2nd")
    df.percentile30 .= Int32.(df."3rd")
    # df.percentile35 .= Int32.(round.((df."4th"- df."3rd")/2) + df."3rd")
    df.percentile40 .= Int32.(df."4th")
    # df.percentile45 .= Int32.(round.((df."5th"- df."4th")/2) + df."4th") 
    df.percentile50 .= Int32.(df."5th")
    # df.percentile55 .= Int32.(round.((df."6th"- df."5th")/2) + df."5th")
    df.percentile60 .= Int32.(df."6th")
    # df.percentile65 .= Int32.(round.((df."7th"- df."6th")/2) + df."6th")
    df.percentile70 .= Int32.(df."7th")
    # df.percentile75 .= Int32.(round.((df."8th"- df."7th")/2) + df."7th")
    df.percentile80 .= Int32.(df."8th")
    # df.percentile85 .= Int32.(round.((df."9th"- df."8th")/2) + df."8th")
    df.percentile90 .= Int32.(df."9th")
    # df.percentile95 .= Int32.(round.((df."10th"- df."9th")/2) + df."9th")
    df.percentile100 .= Int32.(df."10th")
    df.max_income .= Int32.(round.((df."10th"- df."9th")/2) + df."10th") #extrapolate max point of mean income 
    return select(df, Not([:"1st", :"2nd", :"3rd", :"4th", :"5th", :"6th", :"7th", :"8th", :"9th", :"10th"]))
end

export load_data

end #end module