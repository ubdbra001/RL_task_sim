include("Task_sim_functions.jl")

N_options = 2
N_trials = 100
switch_after = 20

V = Array{Float64, 2}(undef, N_options, N_trials)
V[:,1] .= (1/N_options)

correct_resp = new_correct(N_options)

fuzziness = 0.8
α_vals = Dict("pos" => 0.15, "neg"=> 0.1)
