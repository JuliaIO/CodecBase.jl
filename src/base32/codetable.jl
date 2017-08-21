# CodeTable32
# ===========

const CodeTable32 = CodeTable{32}

const BASE32_CODEPAD = 0x20  # PADding
const BASE32_CODEIGN = 0x21  # IGNore
const BASE32_CODEEND = 0x22  # END
const BASE32_CODEERR = 0xff  # ERRor

"""
    CodeTable32(asciistr::String, pad::Char; casesensitive::Bool=false)

Create a base32 code table.
"""
function CodeTable32(asciistr::String, pad::Char; casesensitive::Bool=false)
    if !isascii(asciistr) || !isascii(pad)
        throw(ArgumentError("the code table must be ASCII"))
    elseif length(asciistr) != 32
        throw(ArgumentError("the code size must be 32"))
    end
    encodeword = Vector{UInt8}(32)
    decodeword = Vector{UInt8}(128)
    fill!(decodeword, BASE32_CODEERR)
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
    padcode = UInt8(pad)
    decodeword[padcode+1] = BASE32_CODEPAD
    return CodeTable32(encodeword, decodeword, padcode)
end

function ignorechars!(table::CodeTable32, chars::String)
    return ignorechars!(table, chars, BASE32_CODEIGN)
end

@inline function encode(table::CodeTable32, byte::UInt8)
    return table.encodeword[Int(byte & 0x1f) + 1]
end

@inline function decode(table::CodeTable32, byte::UInt8)
    return table.decodeword[Int(byte)+1]
end

"""
The standard base32 alphabet (cf. Table 3 of RFC4648).
"""
const BASE32_STD = CodeTable32("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", '=')

"""
The extended hex alphabet (cf. Table 4 of RFC4648).
"""
const BASE32_HEX = CodeTable32("0123456789ABCDEFGHIJKLMNOPQRSTUV", '=')
