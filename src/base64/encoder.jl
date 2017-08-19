# Base64 Encoder
# ==============

struct Base64Encoder <: Codec
    table::CodeTable64
    buffer::Buffer
end

"""
    Base64Encoder(urlsafe::Bool=false)

Create a base64 encoding codec.

Arguments
---------
- `urlsafe`: use `-` and `_` as the last two values
"""
function Base64Encoder(;urlsafe::Bool=false)
    if urlsafe
        table = BASE64_URLSAFE
    else
        table = BASE64_STANDARD
    end
    return Base64Encoder(table, Buffer(2))
end

const Base64EncoderStream{S} = TranscodingStream{Base64Encoder,S} where S<:IO

"""
    Base64EncoderStream(stream::IO; kwargs...)

Create a base64 encoding stream (see `Base64Encoder` for `kwargs`).
"""
function Base64EncoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base64Encoder(;kwargs...), stream)
end

function TranscodingStreams.startproc(
        codec :: Base64Encoder,
        state :: Symbol,
        error :: Error)
    empty!(codec.buffer)
    return :ok
end

macro encode64()
    quote
        output[j+1] = encode(table, a >> 2         )
        output[j+2] = encode(table, a << 4 | b >> 4)
        output[j+3] = encode(table, b << 2 | c >> 6)
        output[j+4] = encode(table,          c     )
        j += 4
    end |> esc
end

function TranscodingStreams.process(
        codec  :: Base64Encoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    i = j = 0
    a = b = c = 0x00
    table = codec.table
    buffer = codec.buffer

    if j + 4 > output.size
        # This will expand the output buffer.
        return i, j, :ok
    end

    @assert buffer.size ≤ 2
    if buffer.size == 0 && i + 3 ≤ input.size
        a = input[i+=1]
        b = input[i+=1]
        c = input[i+=1]
    elseif buffer.size == 1 && i + 2 ≤ input.size
        a = buffer[1]
        b = input[i+=1]
        c = input[i+=1]
    elseif buffer.size == 2 && i + 1 ≤ input.size
        a = buffer[1]
        b = buffer[2]
        c = input[i+=1]
    elseif input.size == 0
        if buffer.size == 0
            # ok
        elseif buffer.size == 1
            a = buffer[1]
            output[j+=1] = encode(table, a >> 2)
            output[j+=1] = encode(table, a << 4)
            output[j+=1] = table.padcode
            output[j+=1] = table.padcode
        elseif buffer.size == 2
            a = buffer[1]
            b = buffer[2]
            output[j+=1] = encode(table, a >> 2         )
            output[j+=1] = encode(table, a << 4 | b >> 4)
            output[j+=1] = encode(table,          b << 2)
            output[j+=1] = table.padcode
        else
            # unreachable
            @assert false
        end
        return i, j, :end
    else
        # This avoids infinite loop.
        buffer[buffer.size+=1] = input[i+=1]
        return i, j, :ok
    end
    empty!(buffer)

    @encode64
    @inbounds while i + 3 ≤ input.size && j + 4 ≤ output.size
        a = input[i+1]
        b = input[i+2]
        c = input[i+3]
        i += 3
        @encode64
    end

    # Return #{read bytes}, #{written bytes} and the status.
    return i, j, :ok
end
