# Base16 Decoder
# ==============

struct Base16Decoder <: Codec
    table::CodeTable16
    state::DecodeState
    buffer::Buffer
end

"""
    Base16Decoder()

Create a base16 decoding codec.
"""
function Base16Decoder()
    return Base16Decoder(BASE16_UPPER, DecodeState(), Buffer(1))
end

const Base16DecoderStream{S} = TranscodingStream{Base16Decoder,S} where S<:IO

"""
    Base16DecoderStream(stream::IO)

Create a base16 decoding stream.
"""
function Base16DecoderStream(stream::IO)
    return TranscodingStream(Base16Decoder(), stream)
end

function TranscodingStreams.startproc(
        codec :: Base16Decoder,
        state :: Symbol,
        error :: Error)
    start_decoding!(codec.state)
    return :ok
end

macro decode16(a, b, j)
    quote
        _a = decode(table, $(a))
        _b = decode(table, $(b))
        if _a > 0x0f || _b > 0x0f
            error[] = ArgumentError("invalid data: '$(String([$(a), $(b)]))'")
            status = :error
        end
        output[$(j)] = _a << 4 | _b
    end |> esc
end

function TranscodingStreams.process(
        codec  :: Base16Decoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    i = j = 0
    a = b = 0x00
    table = codec.table
    state = codec.state
    buffer = codec.buffer

    if !is_running(state)
        error[] = ArgumentError("decoding is already finished")
        return i, j, :error
    elseif j + 1 > output.size
        return i, j, :ok
    end

    @assert buffer.size ≤ 1
    if buffer.size == 0 && i + 2 ≤ input.size
        a = input[i+=1]
        b = input[i+=1]
    elseif buffer.size == 1 && i + 1 ≤ input.size
        a = buffer[1]
        b = input[i+=1]
    else
        if buffer.size == 0 && input.size == 0
            finish_decoding!(state)
            return i, j, :end
        elseif input.size > 0
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
    @decode16 a b j+1
    j += 1
    @inbounds while i + 8 ≤ input.size && j + 4 ≤ output.size && status == :ok
        @decode16 input[i+1] input[i+2] j+1
        @decode16 input[i+3] input[i+4] j+2
        @decode16 input[i+5] input[i+6] j+3
        @decode16 input[i+7] input[i+8] j+4
        i += 8
        j += 4
    end
    @inbounds while i + 2 ≤ input.size && j + 1 ≤ output.size && status == :ok
        @decode16 input[i+1] input[i+2] j+1
        i += 2
        j += 1
    end
    if status == :end || status == :error
        finish_decoding!(state)
    end
    return i, j, status
end
