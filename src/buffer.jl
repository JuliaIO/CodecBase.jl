# Buffer
# ======

mutable struct Buffer
    data::Vector{UInt8}
    size::Int
end

Buffer(bufsize) = Buffer(Vector{UInt8}(bufsize), 0)
capacity(buffer::Buffer) = length(buffer.data)
Base.empty!(buffer::Buffer) = buffer.size = 0
Base.getindex(buffer::Buffer, i::Integer) = getindex(buffer.data, i)
Base.setindex!(buffer::Buffer, v, i::Integer) = setindex!(buffer.data, v, i)
