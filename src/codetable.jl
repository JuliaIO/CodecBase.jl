# CodeTable
# =========

struct CodeTable{base}
    # 6-bit => ascii code
    encodeword::Vector{UInt8}

    # ascii code => 6-bit ∩ {BASE64_DECPAD, BASE64_DECERR}?
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
