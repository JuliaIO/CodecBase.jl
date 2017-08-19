# Decode State
# ============

mutable struct DecodeState
    state::Symbol
    DecodeState() = new(:init)
end

function start_decoding!(state::DecodeState)
    state.state = :running
end

function finish_decoding!(state::DecodeState)
    state.state = :finished
end

function is_running(state::DecodeState)
    return state.state == :running
end
