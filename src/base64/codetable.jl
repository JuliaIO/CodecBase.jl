# CodeTable64
# ===========

const CodeTable64 = CodeTable{64}

# These are used to detect padding and invalid data.
const BASE64_DECPAD = UInt8(0x40)
const BASE64_DECERR = UInt8(0xff)

function CodeTable64(asciistr::String, pad::Char)
    if !isascii(asciistr) || !isascii(pad)
        throw(ArgumentError("the code table must be ASCII"))
    elseif length(asciistr) != 64
        throw(ArgumentError("the code size must be 64"))
    end
    encodeword = Vector{UInt8}(64)
    decodeword = Vector{UInt8}(256)
    fill!(decodeword, BASE64_DECERR)
    for (i, char) in enumerate(asciistr)
        bits = UInt8(i-1)
        code = UInt8(char)
        encodeword[bits+1] = code
        decodeword[code+1] = bits
    end
    padcode = UInt8(pad)
    decodeword[padcode+1] = BASE64_DECPAD
    return CodeTable64(encodeword, decodeword, padcode)
end

@inline function encode(table::CodeTable64, byte::UInt8)
    return table.encodeword[Int(byte & 0x3f) + 1]
end

@inline function decode(table::CodeTable64, byte::UInt8)
    return table.decodeword[Int(byte)+1]
end

const BASE64_STANDARD = CodeTable64(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", '=')
const BASE64_URLSAFE = CodeTable64(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_", '=')
