# CodeTable
# =========

struct CodeTable{base}
    # n-bit code => ascii code
    encodeword::Vector{UInt8}

    # ascii code => n-bit code
    decodeword::Vector{UInt8}

    # ascii code for padding
    padcode::UInt8
end

function Base.copy(table::CodeTable{base}) where base
    return CodeTable{base}(
        copy(table.encodeword),
        copy(table.decodeword),
        table.padcode)
end

const whitespace = "\t\n\v\f\r "

# Add ignored characters to the table.
function ignorechars!(table::CodeTable, chars::String, code_ignore::UInt8)
    if !isascii(chars)
        throw(ArgumentError("ignored characters must be ASCII"))
    end
    for char in chars
        code = UInt8(char)
        table.decodeword[code+1] = code_ignore
    end
    return table
end
