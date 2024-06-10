import Base: eof, peek, position

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

"""
    eof(l::Lexer) -> Bool
"""
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

"""
    position(l::Lexer) -> Int
"""
position(l::Lexer) = l.pos

function eat!(l::Lexer)
    p0 = position(l)
    p1 = position(l)
    while true
        c = peek(l)
        if isnothing(c) || isseparator(c)
            break
        end
        p1 = position(l)
        next!(l)
    end
    l.str[p0:p1]
end

function lexnull!(l::Lexer, result::Vector{Token})
    str = eat!(l)
    str == "null" || throw(LexerError("invalid token $str"))
    push!(result, NullToken())
end

function lextrue!(l::Lexer, result::Vector{Token})
    str = eat!(l)
    str == "true" || throw(LexerError("invalid token $str"))
    push!(result, BooleanToken(true))
end

function lexfalse!(l::Lexer, result::Vector{Token})
    str = eat!(l)
    str == "false" || throw(LexerError("invalid token $str"))
    push!(result, BooleanToken(false))
end

function lexstring!(l::Lexer, result::Vector{Token})
    p0 = position(l)
    p1 = position(l)
    next!(l)
    while true
        c = peek(l)
        if c == '"'
            p1 = position(l)
            next!(l)
            break
        elseif c == '\\'
            p1 = position(l)
            next!(l)
            c = peek(l)
            if c == '\x22' || c == '\x5c' || c == '\x2f' || c == '\x62' || c == '\x66' || c == '\x6e' || c == '\x72' || c == '\x74'
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
        p1 = position(l)
        next!(l)
    end
    str = l.str[p0:p1]
    push!(result, StringToken(str))
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
            lexnull!(l, result)
        elseif c == 't'
            lextrue!(l, result)
        elseif c == 'f'
            lexfalse!(l, result)
        elseif c == '"'
            lexstring!(l, result)
        elseif c in '1':'9'
            p0 = position(l)
            p1 = position(l)
            next!(l)
            while true
                c = peek(l)
                if isnothing(c) || iswhitespace(c) || isseparator(c)
                    str = l.str[p0:p1]
                    n = Base.parse(Int64, str)
                    push!(result, NumberToken(n))
                    break
                elseif c in '0':'9'
                elseif c == '.'
                    # decimal-point
                    next!(l)
                    while true
                        c = peek(l)    
                        if c == '0':'9'
                            # int
                            # pass
                        elseif iswhitespace(c) || isseparator(c)
                            break
                        elseif c == 'e' || c == 'E' # e
                            next!(l)
                            c = peek(l)
                            if iswhitespace(c) || isseparator(c)
                                break
                            elseif c == '+' || c == '-'
                                if c in '0':'9' # 1*DIGIT
                                else
                                    throw(LexorError("invalid token"))
                                end
                            elseif c in '0':'9' # 1*DIGIT
                                
                            else
                                throw(LexorError("invalid token"))
                            end
                        else
                            throw(LexerError("invalid token"))
                        end
                        next!(l)
                    end
                    break
                elseif c == 'e' || c == 'E'
                    error("not implemented")
                else
                    throw(LexerError("invalid token"))
                end
                p1 = position(l)
                next!(l)
            end
        elseif c == '0'
            error("not implemented")
        elseif c == '-'
            error("not implemented")
        else
            throw(LexerError("invalid token: $c"))
        end
    end
    result
end

lex(str::AbstractString)::Vector{<:Token} = lex!(Lexer(String(str)))
lex(io::IO)::Vector{<:Token} = lex(read(io, String))
