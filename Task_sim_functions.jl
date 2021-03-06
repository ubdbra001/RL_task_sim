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

    options, = findallmax(V)
	response = rand(options)
	
	return(response)
end

function generate_feedback(given_resp::Int, correct_resp::Int,
    N_options::Int, fuzziness::AbstractFloat)
# Generate feedback for response, feedback will depend on whether the response was
# correct or not and user defined setting for how trustworthy the feedback should be
# Inputs:
#   correct_resp: Int indicating the current correct stimulus
#   actual_resp: Int indicating the chosen stimulus
#   N_options: Int indicating the number of potential options
#   fuzziness: Float between 0 and 1 indicating how trustworthy the feedback
#              should be. Nearer 1 makes the feedback more trustworthy,
#              nearer 0 makes the feedback less trustworthy 

    # To give a correct response the given and correct responses should match
    # and a random number shuold be less than the fuziness threshold 
	if correct_resp == given_resp && rand() < fuzziness
        # Not sure why this is like this
		response_vec = zeros(N_options)
		response_vec[correct_resp] = 1
	else
    # Currently this will always accurately say if the response was incorrect,
    # may need to update this

        # As before not sure why I did it like this
		response_vec = ones(N_options)
		response_vec[given_resp] = 0
	end

	return response_vec
end

function update_correct(N_options::Int; prev_corr = nothing)::Int
# Chooses a new correct response from the options available,
# if previous correct response is provided then it is removed from
# the potential options
# Inputs:
#   N_options: Integer specifying the number of potential options
#   prev_corr: Integer specifying the previous correct option, which is
#              removed from the pool of potential new correct options, by
#              default it is nothing
# Outputs:
#   correct_resp: Int specifying the new correct response
	
	potential_responses = Vector(1:N_options)
	
	if !isnothing(prev_corr) && length(potential_responses) > 1
		deleteat!(potential_responses, prev_corr)
	end
	
	correct_resp = rand(potential_responses)
	return(correct_resp)
end


function dual_learning_rate(??_vals::Dict, ??)
# Not sure how this works 
    pos_learn = ??_vals["pos"] .* (?? .> 0)
    neg_learn = ??_vals["neg"] .* (?? .<= 0)
    
    ?? = pos_learn + neg_learn
        
    return(??)
end

function RW_learning(values::AbstractArray{<:Real}, responses::AbstractVector{<:Int},
    ??_vals::Dict, correct_resp::Int, cr_switch::Int, max_trials::Int, fuzziness::AbstractFloat)
# Recursive reversal learning task takes in properties and produces a matrix of
# values for each of the stimuli
# Will call itself until the specified max number of trials are reached
# Inputs:
#   values: Matrix containing present and past values for the stimuli
#   responses: Vector of integers representing responses given by the agent
#   ??_vals: Dict containg positive and negative reward values
#   correct_resp: Integer indicating the location of the current correct response
#   cr_switch: Integer specifying number of trials before the correct response changes
#   max_trials: Integer specifying the number of trials before exiting
#   fuzziness: Float specifying the probability that the correct response will be rewarded
# Outputs:
#   values: Matrix of the values for each stimuli

    # Get the most recent values for the stimuli and softmax them
	V_curr = values[:, length(responses)]
	V_soft = softmax(V_curr)
	
    # Select a response and add that to the response vector
	Q = select_response(V_soft)
    push!(responses, Q)

    # How many trials have been completed
	N_trials = length(responses)
	
    # Check whether that response is rewarded or not
	Q_vec = generate_feedback(Q, correct_resp, length(V_curr), fuzziness)
	
    # Calculate the delta
	?? = (Q_vec - V_curr)

    # Adjust the reward values according to the delta
	?? = dual_learning_rate(??_vals, ??)

    # Generate the stimuli values for the current trial and add that to the
    # values matrix  
	V_new = V_curr .+ (?? .* ??)
	values[:,N_trials] = V_new
	
    # If we've reached a switch point then choose a new correct response
	if N_trials % cr_switch == 0
		correct_resp = update_correct(length(V_curr); prev_corr = correct_resp)
	end
	
    # If we've reached the max number of trials then break out of the function
	if N_trials == max_trials
		return(values)
	else # Otherwise run the function again with the new values
		RW_learning(values, responses, ??_vals, correct_resp, cr_switch, max_trials, fuzziness)
	end
	
end


function RW_learning(current_vals::AbstractVector{<:AbstractFloat},
    ??_vals::Dict, correct_resp::Int, fuzziness::AbstractFloat)
# Non-recursive Reversal learning task
# Inputs:
#	Current_vals: Vector of current stimulus values
#	??_vals: Dict specifying reward values
#	correct_resp: Integer specifying current correct response
# 	fuzziness: Float specifying the trustworthiness of the feedback given
# Outputs:
#	V_new: Vector of reward values for each stimulus, updated based on feedback
#		   to response
#	response: Int specifying the most recent response 

	# Softmax current reward values
	V_soft = softmax(current_vals)
	
    # Select a response
	Q = select_response(V_soft)
    
    # Check whether that response is rewarded or not
	Q_vec = generate_feedback(Q, correct_resp, length(V_soft), fuzziness)
	
    # Calculate the delta
	?? = (Q_vec - current_vals)

    # Adjust the reward values according to the delta
	?? = dual_learning_rate(??_vals, ??)

    # Generate the stimuli values for the current trial return these values and
	# the response
	V_new = current_vals .+ (?? .* ??)
	return(V_new, Q)

end