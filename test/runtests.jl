using CodecBase
using Base.Test
import TranscodingStreams:
    TranscodingStream,
    test_roundtrip_read,
    test_roundtrip_write,
    test_roundtrip_lines,
    test_roundtrip_transcode

@testset "Base16" begin
    @test transcode(Base16Encoder(), b"") == b""
    @test transcode(Base16Encoder(), b"f") == b"66"
    @test transcode(Base16Encoder(), b"fo") == b"666F"
    @test transcode(Base16Encoder(), b"foo") == b"666F6F"
    @test transcode(Base16Encoder(), b"foob") == b"666F6F62"
    @test transcode(Base16Encoder(), b"fooba") == b"666F6F6261"
    @test transcode(Base16Encoder(), b"foobar") == b"666F6F626172"

    @test transcode(Base16Decoder(), b"") == b""
    @test transcode(Base16Decoder(), b"66") == b"f"
    @test transcode(Base16Decoder(), b"666F") == b"fo"
    @test transcode(Base16Decoder(), b"666F6F") == b"foo"
    @test transcode(Base16Decoder(), b"666F6F62") == b"foob"
    @test transcode(Base16Decoder(), b"666F6F6261") == b"fooba"
    @test transcode(Base16Decoder(), b"666F6F626172") == b"foobar"
    @test transcode(Base16Decoder(), b"666f6F626172") == b"foobar"

    @test_throws ArgumentError transcode(Base16Decoder(), b"a")
    @test_throws ArgumentError transcode(Base16Decoder(), b"aaa")
    @test_throws ArgumentError transcode(Base16Decoder(), b"aaaaa")
    @test_throws ArgumentError transcode(Base16Decoder(), b"\0")
    @test_throws ArgumentError transcode(Base16Decoder(), b"a\0")
    @test_throws ArgumentError transcode(Base16Decoder(), b"aa\0")
    @test_throws ArgumentError transcode(Base16Decoder(), b"aaa\0")

    test_roundtrip_read(Base16EncoderStream, Base16DecoderStream)
    test_roundtrip_write(Base16EncoderStream, Base16DecoderStream)
    test_roundtrip_lines(Base16EncoderStream, Base16DecoderStream)
    test_roundtrip_transcode(Base16Encoder, Base16Decoder)
end

@testset "Base64" begin
    @test transcode(Base64Encoder(), b"") == b""
    @test transcode(Base64Encoder(), b"f") == b"Zg=="
    @test transcode(Base64Encoder(), b"fo") == b"Zm8="
    @test transcode(Base64Encoder(), b"foo") == b"Zm9v"
    @test transcode(Base64Encoder(), b"foob") == b"Zm9vYg=="
    @test transcode(Base64Encoder(), b"fooba") == b"Zm9vYmE="
    @test transcode(Base64Encoder(), b"foobar") == b"Zm9vYmFy"

    @test transcode(Base64Decoder(), b"") == b""
    @test transcode(Base64Decoder(), b"Zg==") == b"f"
    @test transcode(Base64Decoder(), b"Zm8=") == b"fo"
    @test transcode(Base64Decoder(), b"Zm9v") == b"foo"
    @test transcode(Base64Decoder(), b"Zm9vYg==") == b"foob"
    @test transcode(Base64Decoder(), b"Zm9vYmE=") == b"fooba"
    @test transcode(Base64Decoder(), b"Zm9vYmFy") == b"foobar"

    @test transcode(Base64Decoder(), b"Zg=\n=") == b"f"
    @test transcode(Base64Decoder(), b"Zm9v\nYmFy") == b"foobar"
    @test transcode(Base64Decoder(), b"Zg=\r\n=") == b"f"
    @test transcode(Base64Decoder(), b"Z m  9\rv\r\nYm\nF\t\ty") == b"foobar"
    @test transcode(Base64Decoder(), b"  Zm9vYmFy  ") == b"foobar"
    @test transcode(Base64Decoder(), b"      Zm     9v      Ym    Fy      ") == b"foobar"

    @test_throws ArgumentError transcode(Base64Decoder(), b"a")
    @test_throws ArgumentError transcode(Base64Decoder(), b"aa")
    @test_throws ArgumentError transcode(Base64Decoder(), b"aaa")
    @test_throws ArgumentError transcode(Base64Decoder(), b"aaaaa")
    @test_throws ArgumentError transcode(Base64Decoder(), b"\0")
    @test_throws ArgumentError transcode(Base64Decoder(), b"a\0")
    @test_throws ArgumentError transcode(Base64Decoder(), b"aa\0")
    @test_throws ArgumentError transcode(Base64Decoder(), b"aaa\0")

    test_roundtrip_read(Base64EncoderStream, Base64DecoderStream)
    test_roundtrip_write(Base64EncoderStream, Base64DecoderStream)
    test_roundtrip_lines(Base64EncoderStream, Base64DecoderStream)
    test_roundtrip_transcode(Base64Encoder, Base64Decoder)
end
