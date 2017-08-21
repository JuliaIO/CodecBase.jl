# CodeTable16
# ===========

const CodeTable16 = CodeTable{16}

const BASE16_CODEIGN = 0x10  # IGNore
const BASE16_CODEEND = 0x11  # END
const BASE16_CODEERR = 0xff  # ERRor

function CodeTable16(asciistr::String, casesensitive::Bool)
    if !isascii(asciistr)
        throw(ArgumentError("the code table must be ASCII"))
    elseif length(asciistr) != 16
        throw(ArgumentError("the code size must be 16"))
    end
    encodeword = Vector{UInt8}(16)
    decodeword = Vector{UInt8}(256)
    fill!(decodeword, BASE16_CODEERR)
    for (i, char) in enumerate(asciistr)
        bits = UInt8(i-1)
        code = UInt8(char)
        encodeword[bits+1] = code
        decodeword[code+1] = bits
        if !casesensitive
            if isupper(char)
                code = UInt8(lowercase(char))
                decodeword[code+1] = bits
            end
            if islower(char)
                code = UInt8(uppercase(char))
                decodeword[code+1] = bits
            end
        end
    end
    # NOTE: The padcode is not used.
    return CodeTable16(encodeword, decodeword, 0x00)
end

function ignorechars!(table::CodeTable16, chars::String)
    return ignorechars!(table, chars, BASE16_CODEIGN)
end

@inline function encode(table::CodeTable16, x::UInt8)
    return table.encodeword[Int(x)+1]
end

@inline function decode(table::CodeTable16, x::UInt8)
    return table.decodeword[Int(x)+1]
end

const BASE16_UPPER = CodeTable16("0123456789ABCDEF", false)
const BASE16_LOWER = CodeTable16("0123456789abcdef", false)
