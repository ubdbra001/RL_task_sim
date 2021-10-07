using ElasticArrays

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

function select_response(V::AbstractVector{<:Real})::Int
# Chooses response from options, if there is only one option
# then that one is chosen, otherwise pick randomly from options
# Inputs:
#   V: Vector of response options
# Outputs:
#   Response: Chosen response option returned as Int

    options = findallmax(V)
	response = rand(options)
	
	return(response)
end



function RW_learning(values, responses, α_vals,
    correct_resp::Int, cr_switch::Int, max_trials;;Int, fuzziness::Float)
# Recursive reversal learning task takes in properties and produces a matrix of
# values for each of the stimuli
# Will call itself until the specified max number of trials are reached
# Inputs:
#   values: Matrix containing present and past values for the stimuli
#   responses: Vector of integers representing responses given by the agent
#   α_vals: Dict containg positive and negative reward values
#   correct_resp: Integer indicating the location of the current correct response
#   cr_switch: Integer specifying number of trials before the correct response changes
#   max_trials: Integer specifying the number of trials before exiting
#   fuzziness: Float specifying the probability that the correct response will be rewarded
# Outputs:
#   values: Matrix of the values for each stimuli

    # Get the most recent values for the stimuli and softmax them
	V_curr = values[:,end]
	V_soft = softmax(V_curr)
	
    # Select a response and add that to the response vector
	Q = select_response(V_soft)
	push!(responses, Q)

    # Check whether that response is rewarded or not
	Q_vec = check_answer(correct_resp, Q, length(V_curr), fuzziness)
	
    # Calculate the delta
	δ = (Q_vec - V_curr)

    # Adjust the reward values according to the delta
	α = dualLearningRate(α_vals, δ)

    # Generate the stimuli values for the current trial and add that to the
    # values matrix  
	V_new = V_curr .+ (α .* δ)
	append!(values, V_new)
	
    # How many trials have been completed
	N_trials = length(responses)
	
    # If we've reached a switch point then choose a new correct response
	if N_trials % cr_switch == 0
		correct_resp = new_correct(length(V_curr); prev_corr = correct_resp)
	end
	
    # If we've reached the max number of trials then break out of the function
	if N_trials == max_trials
		return(values)
	else # Otherwise run the function again with the new values
		RW_learning(values, responses, α_vals, correct_resp, cr_switch, max_trials, fuzziness)
	end
	
end