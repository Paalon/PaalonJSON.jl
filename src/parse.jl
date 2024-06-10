import Base: eof, peek

struct ParserError <: Exception
    msg::String
end

"""
    Parser

Parser for JSON.
"""
mutable struct Parser
    tokens::Vector{<:Token}
    pos::Int
end

Parser(tokens::Vector{<:Token}) = Parser(tokens, firstindex(tokens))

Parser(str::String) = Parser(lex(str))

eof(p::Parser) = length(p.tokens) < p.pos

"""
    peek(p::Parser) -> Union{Token, Nothing}
"""
peek(p::Parser) = eof(p) ? nothing : p.tokens[p.pos]

"""
    next!(p::Parser) -> Union{Token, Nothing}

Advance the parser to the next state.
"""
function next!(p::Parser)::Union{Token, Nothing}
    state = iterate(p.tokens, p.pos)
    isnothing(state) && return nothing
    token, p.pos = state
    token
end

parsenull(::NullToken) = JSONNull()
parseboolean(token::BooleanToken) = JSONBoolean(token.value)
parsestring(token::StringToken) = JSONString(token.value[begin+1:end-1])
parsenumber(token::NumberToken) = JSONNumber(parse(Float64, token.value))

const eoftokenexception = ErrorException("unexpected end of token")
const unexpectedtokenexception = ErrorException("unexpected token")

function parsearray_expectvalue!(p::Parser, result::JSONArray)
    t = peek(p)
    if t isa NullToken
        push!(result, dump(parsenull(t)))
        next!(p)
    elseif t isa BooleanToken
        push!(result, dump(parseboolean(t)))
        next!(p)
    elseif t isa StringToken
        push!(result, dump(parsestring(t)))
        next!(p)
    elseif t isa NumberToken
        push!(result, dump(parsenumber(t)))
        next!(p)
    elseif t isa BeginArrayToken
        next!(p)
        push!(result, dump(parsearray!(p)))
    elseif t isa BeginObjectToken
        next!(p)
        push!(result, dump(parseobject!(p)))
    else # not a value
        throw(unexpectedtokenexception)
    end
    t = peek(p)
    if t isa ValueSeparatorToken
        next!(p)
        parsearray_expectvalue!(p, result)
    elseif t isa EndArrayToken
        next!(p)
    else
        throw(unexpectedtokenexception)
    end
    nothing
end

function parsearray!(p::Parser)
    result = JSONArray()
    t = peek(p)
    if t isa EndArrayToken
        next!(p)
    else
        parsearray_expectvalue!(p, result)
    end
    result
end

function parseobject!(p::Parser)
    result = JSONObject()
    t = next!(p)
    isa(t, EndObjectToken) && return result
    while true
        # expect and parse string
        !isa(t, StringToken) && throw(ParserError("non-string object key: $t"))
        key = dump(parsestring(t))
        # expect and parse name separator
        t = next!(p)
        !isa(t, NameSeparatorToken) && throw(unexpectedtokenexception)
        # expect and parse value
        value = dump(parsevalue!(p))
        result[key] = value
        # expect and parse end object token or value separator
        t = next!(p)
        if isa(t, EndObjectToken)
            break
        elseif isa(t, ValueSeparatorToken)
            t = next!(p)
            continue
        else
            throw(unexpectedtokenexception)
        end
    end
    result
end

function parsevalue!(p::Parser)::JSONValue
    eof(p) && throw(EOFError)
    t = next!(p)
    if t isa NullToken
        parsenull(t)
    elseif t isa BooleanToken
        parseboolean(t)
    elseif t isa StringToken
        parsestring(t)
    elseif t isa NumberToken
        parsenumber(t)
    elseif t isa BeginArrayToken
        parsearray!(p)
    elseif t isa BeginObjectToken
        parseobject!(p)
    else
        throw(unexpectedtokenexception)
    end
end

function parse!(p::Parser)
    result = parsevalue!(p)
    eof(p) || error("not end of the parser.")
    dump(result)
end

parse(str::AbstractString) = parse!(Parser(String(str)))
parse(io::IO) = parse(read(io, String))
