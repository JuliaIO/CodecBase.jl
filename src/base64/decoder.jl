# Base64 Decoder
# ==============

struct Base64Decoder <: Codec
    table::CodeTable64
    state::DecodeState
    buffer::Buffer
end

"""
    Base64Decoder(;urlsafe::Bool=false)

Create a base64 decoding codec.

Arguments
---------
- `urlsafe`: use `-` and `_` as the last two values
"""
function Base64Decoder(;urlsafe::Bool=false)
    if urlsafe
        table = BASE64_URLSAFE
    else
        table = BASE64_STANDARD
    end
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

macro decode64()
    quote
        _a = decode(table, a)
        _b = decode(table, b)
        _c = decode(table, c)
        _d = decode(table, d)
        if _a > 0x3f || _b > 0x3f || _c > 0x3f || _d > 0x3f
            if _a ≤ 0x3f && _b ≤ 0x3f && _c ≤ 0x3f && _d == BASE64_DECPAD
                npad = 1
                _d = 0x00
                status = :end
            elseif _a ≤ 0x3f && _b ≤ 0x3f && _c == _d == BASE64_DECPAD
                npad = 2
                _c = _d = 0x00
                status = :end
            else
                error[] = ArgumentError(
                    "invalid data: '$(String([a, b, c, d]))'")
                status = :error
            end
        end
        output[j+1] = (_a << 2) | (_b >> 4)
        output[j+2] = (_b << 4) | (_c >> 2)
        output[j+3] = (_c << 6) |  _d
        j += 3
    end |> esc
end

function TranscodingStreams.process(
        codec  :: Base64Decoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    i = j = 0
    a = b = c = d = 0x00
    table = codec.table
    state = codec.state
    buffer = codec.buffer

    if !is_running(state)
        error[] = ArgumentError("decoding is already finished")
        return i, j, :error
    elseif j + 3 > output.size
        # This will expand the output buffer.
        return i, j, :ok
    end

    @assert buffer.size ≤ 3
    if buffer.size == 0 && i + 4 ≤ input.size
        a = input[i+=1]
        b = input[i+=1]
        c = input[i+=1]
        d = input[i+=1]
    elseif buffer.size == 1 && i + 3 ≤ input.size
        a = buffer[1]
        b = input[i+=1]
        c = input[i+=1]
        d = input[i+=1]
    elseif buffer.size == 2 && i + 2 ≤ input.size
        a = buffer[1]
        b = buffer[2]
        c = input[i+=1]
        d = input[i+=1]
    elseif buffer.size == 3 && i + 1 ≤ input.size
        a = buffer[1]
        b = buffer[2]
        c = buffer[3]
        d = input[i+=1]
    else
        if buffer.size == 0 && input.size == 0
            finish_decoding!(state)
            return i, j, :end
        elseif input.size > 0
            # This avoids infinite loop.
            buffer[buffer.size+=1] = input[i+=1]
            return i, j, :ok
        else
            error[] = ArgumentError("unexpected end of input")
            finish_decoding!(state)
            return i, j, :error
        end
    end
    empty!(buffer)

    status = :ok
    npad = 0
    @decode64
    @inbounds while i + 4 ≤ input.size && j + 3 ≤ output.size && status == :ok
        a = input[i+1]
        b = input[i+2]
        c = input[i+3]
        d = input[i+4]
        i += 4
        @decode64
    end
    if status == :end
        j -= npad
    end
    if status == :end || status == :error
        finish_decoding!(state)
    end
    return i, j, status
end
