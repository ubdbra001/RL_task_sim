using ElasticArrays, Plots

function softmax(V::AbstractVector{<:Real}; B = 1)
# Converts Vector of values into softmaxed values
# (Sum to one)
# Inputs:
#   V: Vector of real values 
#   B: Temp parameter (default 1)
# Output:
#   V_softmax: Softmaxed values of V
    V_softmax = exp.(B * V)/sum(exp.(B * V))
	return(V_softmax)
end
