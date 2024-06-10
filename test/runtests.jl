using Test
import PaalonJSON
const JSON = PaalonJSON

@testset "token" begin
    @test string(JSON.BeginObjectToken()) == "{"
    @test string(JSON.EndObjectToken()) == "}"
    @test string(JSON.BeginArrayToken()) == "["
    @test string(JSON.EndArrayToken()) == "]"
    @test string(JSON.NameSeparatorToken()) == ":"
    @test string(JSON.ValueSeparatorToken()) == ","
    @test string(JSON.NullToken()) == "null"
    @test string(JSON.BooleanToken(true)) == "true"
    @test string(JSON.BooleanToken(false)) == "false"
    @test string(JSON.StringToken("hello")) == "\"hello\""
    @test string(JSON.NumberToken("3.14")) == "3.14"
end

@testset "lex" begin
    @test JSON.lex("null") == [JSON.NullToken()]
    @test JSON.lex("true") == [JSON.BooleanToken(true)]
    @test JSON.lex("false") == [JSON.BooleanToken(false)]
    @test JSON.lex("\"hello\"") == [JSON.StringToken("\"hello\"")]
    @test JSON.lex("[null]") == [JSON.BeginArrayToken(), JSON.NullToken(), JSON.EndArrayToken()]
    @test JSON.lex("[null,null]") == [JSON.BeginArrayToken(), JSON.NullToken(), JSON.ValueSeparatorToken(), JSON.NullToken(), JSON.EndArrayToken()]
    @test JSON.lex("""{"hello":"world"}""") == [JSON.BeginObjectToken(), JSON.StringToken("\"hello\""), JSON.NameSeparatorToken(), JSON.StringToken("\"world\""), JSON.EndObjectToken()]
end

@testset "parse" begin
    @test JSON.parse("null") === nothing
    @test JSON.parse("true") === true
    @test JSON.parse("false") === false
    @test JSON.parse("\"hello\"") == "hello"
    @test JSON.parse("[]") == []
    @test JSON.parse("[null]") == [nothing]
    @test JSON.parse("[null,null]") == [nothing, nothing]
    @test JSON.parse("[null,null,null,null]") == [nothing, nothing, nothing, nothing]
    @test JSON.parse("[null,[null,null],null]") == [nothing, [nothing, nothing], nothing]
    @test JSON.parse("[[[[[[[[[]]]]]]]]]") == [[[[[[[[[]]]]]]]]]
    @test JSON.parse("{}") == Dict{String, Any}()
    @test JSON.parse("""{"hello":"world"}""") == Dict{String, Any}("hello" => "world")
    @test JSON.parse("""{"a":"apple","b":"banana"}""") == Dict{String, Any}("a" => "apple", "b" => "banana") 
end

const filenames = [
    "example1"
    "example2"
]

@testset "parse 2" begin
    for filename in filenames
        open("data/$filename.json", "r") do json
            data_jl = include("data/$filename.jl")     
            data_json = JSON.parse(json)
            @test data_json == data_jl
        end
    end
end

@testset "print" begin
    io = IOBuffer()
    JSON.print(io, nothing)
    @test String(take!(io)) == "null"
    JSON.print(io, true)
    @test String(take!(io)) == "true"
    JSON.print(io, false)
    @test String(take!(io)) == "false"
    JSON.print(io, 110)
    @test String(take!(io)) == "110"
    JSON.print(io, "hello")
    @test String(take!(io)) == "\"hello\""
    JSON.print(io, [])
    @test String(take!(io)) == "[]"
    JSON.print(io, Dict())
    @test String(take!(io)) == "{}"
    dict = Dict{String, Any}(
        "Image" => Dict{String, Any}(
            "Width" => "800",
            "Height" => "600",
            "Title" => "View from 15th Floor",
            "Thumbnail" => Dict{String, Any}(
                "Url" => "http://www.example.com/image/481989943",
                "Height" => "125",
                "Width" => "100",
            ),
            "Animated" => false,
            "IDs" => Any["116", "943", "234", "38793"],
        ),
    )
    JSON.print(io, dict)
    @test String(take!(io)) == """{"Image":{"Width":"800","Height":"600","Thumbnail":{"Width":"100","Height":"125","Url":"http://www.example.com/image/481989943"},"Animated":false,"Title":"View from 15th Floor","IDs":["116","943","234","38793"]}}"""
    close(io)
end
