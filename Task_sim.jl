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

# Run simulation
@time V_out = RW_learning(V, [0], α_vals, correct_resp, switch_after, N_trials, fuzziness)

plot(V_out', label = nothing, ylims = [0,1], marker = :c, markersize = 1)