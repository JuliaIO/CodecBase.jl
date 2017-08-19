# Base16 Encoder
# ==============

struct Base16Encoder <: Codec
    table::CodeTable16
end

"""
    Base16Encoder(;uppercase=true)

Create a base16 encoding codec.

Arguments
- `uppercase`: use [0-9A-F] instead of [0-9a-f].
"""
function Base16Encoder(;uppercase::Bool=true)
    if uppercase
        table = BASE16_UPPER
    else
        table = BASE16_LOWER
    end
    return Base16Encoder(table)
end

const Base16EncoderStream{S} = TranscodingStream{Base16Encoder,S} where S<:IO

"""
    Base16EncoderStream(stream::IO; kwargs...)

Create a base16 encoding stream (see `Base16Encoder` for `kwargs`).
"""
function Base16EncoderStream(stream::IO; kwargs...)
    return TranscodingStream(Base16Encoder(;kwargs...), stream)
end

macro encode16(i, j1, j2)
    quote
        a = input[$(i)]
        output[$(j1)] = encode(table, a >> 4)
        output[$(j2)] = encode(table, a & 0x0f)
    end |> esc
end

function TranscodingStreams.process(
        codec  :: Base16Encoder,
        input  :: Memory,
        output :: Memory,
        error  :: Error)
    i = j = 0
    table = codec.table
    if input.size == 0
        return i, j, :end
    elseif j + 2 > output.size
        return i, j, :ok
    end
    k = min(fld(input.size - i, 4), fld(output.size - j, 8))
    @inbounds while k > 0  # ≡ i + 4 ≤ input.size && j + 8 ≤ output.size
        # unrolled loop
        @encode16 i+1 j+1 j+2
        @encode16 i+2 j+3 j+4
        @encode16 i+3 j+5 j+6
        @encode16 i+4 j+7 j+8
        i += 4
        j += 8
        k -= 1
    end
    @inbounds while i + 1 ≤ input.size && j + 2 ≤ output.size
        @encode16 i+1 j+1 j+2
        i += 1
        j += 2
    end
    return i, j, :ok
end
