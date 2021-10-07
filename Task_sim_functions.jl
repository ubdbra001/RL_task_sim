using ElasticArrays, Plots

function softmax(V::AbstractVector{<:Real}; B = 1)
# Converts Vector of values into softmaxed values
# (Sum to one)
# Inputs:
#   V: Vector of real values 
#   B: Temp parameter (default = 1)
# Output:
#   V_softmax: Vector with softmaxed values of V
    V_softmax = exp.(B * V)/sum(exp.(B * V))
	return(V_softmax)
end

function softmax(R_in::Real; B = 1)
# Dispatch to deal with single number being sent to function
# instead of vector
# Inputs:
#   R_in: Real number
#   B: Temp parameter (default = 1)
# Output:
#   V_softmax: Vector with softmaxed values of V

    V_softmax = softmax([R_in]; B)
    return(V_softmax)
end

function findallmax(V::AbstractVector{<:Real})
# Find the positions of the maximum value in a vector
# Returns all positions for joint max values
# Input:
#   V: Vector of Real values
# Output:
#   val_pos: Vector of positions
#   val: Maximum value
	val, _ = findmax(V)
	val_pos = findall(V .== val)
	
	return val_pos, val
end