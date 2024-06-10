import Base: eof, peek

struct LexerError <: Exception
    msg::String
end

LexerError() = LexerError("")

"""
    Lexer

Lexer for JSON.
"""
mutable struct Lexer
    str::String
    pos::Int
end

Lexer(str::String) = Lexer(str, firstindex(str))

eof(l::Lexer) = ncodeunits(l.str) < l.pos

"""
    peek(l::Lexer) -> Union{Char, Nothing}
"""
peek(l::Lexer) = eof(l) ? nothing : l.str[l.pos]

"""
    next!(l::Lexer) -> Union{Char, Nothing}
"""
function next!(l::Lexer)
    state = iterate(l.str, l.pos)
    isnothing(state) && return
    c, l.pos = state
    c
end

function lex!(l::Lexer)
    result = Token[]
    while true
        c = peek(l)
        isnothing(c) && break
        if iswhitespace(c)
            next!(l)
        elseif c == leftbracechar
            push!(result, BeginObjectToken())
            next!(l)
        elseif c == rightbracechar 
            push!(result, EndObjectToken())
            next!(l)
        elseif c == leftbracketchar
            push!(result, BeginArrayToken())
            next!(l)
        elseif c == rightbracketchar
            push!(result, EndArrayToken())
            next!(l)
        elseif c == colonchar
            push!(result, NameSeparatorToken())
            next!(l)
        elseif c == commachar
            push!(result, ValueSeparatorToken())
            next!(l)
        elseif c == 'n'
            str = ""
            while true
                c = peek(l)
                if isnothing(c) || isseparator(c)
                    break
                end
                str *= c
                next!(l)
            end
            str == "null" || throw(LexerError("invalid token $str"))
            push!(result, NullToken())
        elseif c == 't'
            str = ""
            while true
                c = peek(l)
                if isnothing(c) || isseparator(c)
                    break
                end
                str *= c
                next!(l)
            end
            str == "true" || throw(LexerError())
            push!(result, BooleanToken(true))
        elseif c == 'f'
            str = ""
            while true
                c = peek(l)
                if isnothing(c) || isseparator(c)
                    break
                end
                str *= c
                next!(l)
            end
            str == "false" || throw(LexerError())
            push!(result, BooleanToken(false))
        elseif c == '"'
            str = string(next!(l))
            while true
                str *= c = next!(l)
                if c == '"'
                    break
                elseif c == '\\'
                    c = next!(l)
                    if c == '\x22' || c == '\x5c' || c == '\x2f' || c == '\x62' || c == '\x66' || c == '\x6e' || c == '\x72' || c == '\x74'
                        str *= c
                    elseif c == 'u'
                        codepoint = ""
                        codepoint *= next!(l)
                        codepoint *= next!(l)
                        codepoint *= next!(l)
                        codepoint *= next!(l)
                        c = Char(parse(UInt16, codepoint; base=16))
                    else
                        throw(Error("Prohibited string."))
                    end
                elseif c in '\u0000':'\u001f'
                    throw(Error("Prohibited char in string."))
                end
            end
            push!(result, StringToken(str))
        elseif c == '0':'9'
            next!(l)
        else
            throw(LexerError())
        end
    end
    result
end

lex(str::AbstractString)::Vector{<:Token} = lex!(Lexer(String(str)))
lex(io::IO)::Vector{<:Token} = lex(read(io, String))
