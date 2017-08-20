# Base64 Decoder
# ==============

struct Base64Decoder <: Codec
    table::CodeTable64
    state::DecodeState
    buffer::Buffer
end

const whitespace = "\t\n\v\f\r "

"""
    Base64Decoder(;urlsafe::Bool=false, ignore::String="$(escape_string(whitespace))")

Create a base64 decoding codec.

Arguments
---------
- `urlsafe`: use `-` and `_` as the last two values
- `ignore`: ASCII characters that will be ignored while decoding
"""
function Base64Decoder(;urlsafe::Bool=false, ignore::String=whitespace)
    if urlsafe
        table = BASE64_URLSAFE
    else
        table = BASE64_STANDARD
    end
    table = copy(table)
    ignorechars!(table, ignore)
    return Base64Decoder(table, DecodeState(), Buffer(3))
end

const Base64DecoderStream{S} = TranscodingStream{Base64Decoder,S} where S<:IO

"""
    Base64DecoderStream(stream::IO; kwargs...)

Create a base64 decoding stream (see `Base64Decoder` for `kwargs`).
"""
function Base64DecoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base64Decoder(;kwargs...), stream)
end

function TranscodingStreams.startproc(
        codec :: Base64Decoder,
        state :: Symbol,
        error :: Error)
    start_decoding!(codec.state)
    return :ok
end

function TranscodingStreams.process(
        codec  :: Base64Decoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    table = codec.table
    state = codec.state
    buffer = codec.buffer

    # Early returns.
    if !is_running(state)
        error[] = ArgumentError("decoding is already finished")
        return 0, 0, :error
    elseif output.size < 3
        # Not enough space to write the output.  This will expand the output
        # buffer.
        return 0, 0, :ok
    end

    # Load data from the buffer.
    i = j = 0
    a = b = c = d = BASE64_DECIGN
    @assert buffer.size ≤ 3
    if buffer.size ≥ 1
        a = decode(table, buffer[1])
    end
    if buffer.size ≥ 2
        b = decode(table, buffer[2])
    end
    if buffer.size ≥ 3
        c = decode(table, buffer[3])
    end
    empty!(buffer)

    # Start decoding loop.
    status = :ok
    @inbounds while true
        if a > 0x3f || b > 0x3f || c > 0x3f || d > 0x3f
            i, j, status = decode_irregular(table, a, b, c, d, input, i, output, j, error)
        else
            output[j+1] = a << 2 | b >> 4
            output[j+2] = b << 4 | c >> 2
            output[j+3] = c << 6 | d
            j += 3
        end
        if i + 4 ≤ input.size && j + 3 ≤ output.size && status == :ok
            a = decode(table, input[i+1])
            b = decode(table, input[i+2])
            c = decode(table, input[i+3])
            d = decode(table, input[i+4])
            i += 4
        else
            break
        end
    end

    # Epilogue.
    if status == :end || status == :error
        finish_decoding!(state)
    else
        # Consume at least one byte if any.
        while buffer.size < 3 && i + 1 ≤ input.size
            buffer[buffer.size+=1] = input[i+=1]
        end
    end
    return i, j, status
end

# Decode irregular code (e.g. non-alphabet, padding, etc.).
function decode_irregular(table, a, b, c, d, input, i, output, j, error)
    # Skip ignored chars.
    while true
        if a == BASE64_DECIGN
            a, b, c = b, c, d
        elseif b == BASE64_DECIGN
            b, c = c, d
        elseif c == BASE64_DECIGN
            c = d
        elseif d == BASE64_DECIGN
            # pass
        else
            break
        end
        if i + 1 ≤ input.size
            d = decode(table, input[i+=1])
        else
            d = BASE64_DECEND
            break
        end
    end

    # Write output.
    if a ≤ 0x3f && b ≤ 0x3f && c ≤ 0x3f && d ≤ 0x3f
        output[j+=1] = a << 2 | b >> 4
        output[j+=1] = b << 4 | c >> 2
        output[j+=1] = c << 6 | d
        status = :ok
    elseif a ≤ 0x3f && b ≤ 0x3f && c ≤ 0x3f && d == BASE64_DECPAD
        d = 0x00
        output[j+=1] = a << 2 | b >> 4
        output[j+=1] = b << 4 | c >> 2
        status = :end
    elseif a ≤ 0x3f && b ≤ 0x3f && c == d == BASE64_DECPAD
        c = d = 0x00
        output[j+=1] = a << 2 | b >> 4
        status = :end
    elseif a == b == c == BASE64_DECIGN && d == BASE64_DECEND
        status = :end
    else
        error[] = ArgumentError("invalid data")
        status = :error
    end
    return i, j, status
end
