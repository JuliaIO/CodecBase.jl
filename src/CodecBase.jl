module CodecBase

export
    # base 16
    Base16Encoder,
    Base16EncoderStream,
    Base16Decoder,
    Base16DecoderStream,

    # base 64
    Base64Encoder,
    Base64EncoderStream,
    Base64Decoder,
    Base64DecoderStream

import TranscodingStreams:
    TranscodingStreams,
    TranscodingStream,
    Codec,
    Memory,
    Error

include("buffer.jl")
include("codetable.jl")
include("decodestate.jl")
include("base16/codetable.jl")
include("base16/encoder.jl")
include("base16/decoder.jl")
include("base64/codetable.jl")
include("base64/encoder.jl")
include("base64/decoder.jl")

end # module
