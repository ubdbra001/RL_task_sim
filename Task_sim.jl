using Plots
include("Task_sim_functions.jl")

# Trial options
N_options = 3;
N_trials = 1000;
switch_after = 20;

# Pre-alloacte value matrix
V = Array{Float64, 2}(undef, N_options, N_trials);
V[:,1] .= (1/N_options);

# Choose the correct response
correct_resp = update_correct(N_options);

# Set response feedback fuzziness
fuzziness = 0.8;
# Set learning rates
α_vals = Dict("pos" => 0.15, "neg"=> 0.1);

# Run simulation using recursive function
@time V_out = RW_learning(V, [0], α_vals, correct_resp, switch_after, N_trials, fuzziness)

# Run simulation using loop
@time for run_n in 2:N_trials

    current_vals = V[:, run_n-1]

    new_vals, response = RW_learning(current_vals, α_vals, correct_resp, fuzziness)

    if run_n % switch_after == 0
        correct_resp = update_correct(N_options; prev_corr = correct_resp)
    end

    V[:, run_n] = new_vals;

end

plot(V_out', label = nothing, ylims = [0,1], marker = :c, markersize = 1)