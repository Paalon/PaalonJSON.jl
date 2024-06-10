import Base: string, show

"""
    Token

An abstract type represents JSON tokens.
"""
abstract type Token end

"""
    AtomicToken <: Token

An abstract type represents JSON token which represents a JSON value.
"""
abstract type AtomicToken <: Token end

"""
    BeginObjectToken <: Token

A type of a JSON token `{`.
"""
struct BeginObjectToken <: Token end

const beginobjecttoken = BeginObjectToken()

"""
    EndObjectToken <: Token

A type of a JSON token `}`.
"""
struct EndObjectToken <: Token end

const endobjecttoken = EndObjectToken()

"""
    NameSeparatorToken <: Token

A type of a JSON token `:`.
"""
struct NameSeparatorToken <: Token end

const namesparatortoken = NameSeparatorToken()

"""
    ValueSeparatorToken <: Token

A type of a JSON token `,`.
"""
struct ValueSeparatorToken <: Token end

const valueseparatortoken = ValueSeparatorToken()

"""
    BeginArrayToken <: Token

A type of a JSON token '['.
"""
struct BeginArrayToken <: Token end

const beginarraytoken = BeginArrayToken()

"""
    EndArrayToken <: Token

A type of a JSON token `]`.
"""
struct EndArrayToken <: Token end

const endarraytoken = EndArrayToken()

"""
    NullToken <: AtomicToken

A type of a JSON token `null`.
"""
struct NullToken <: AtomicToken end

const nulltoken = NullToken()

"""
    BooleanToken <: AtomicToken

A type of JSON boolean tokens.
"""
struct BooleanToken <: AtomicToken
    value::Bool
end

"""
    StringToken <: AtomicToken

A type of JSON string tokens.
"""
struct StringToken <: AtomicToken
    value::String
end

"""
    NumberToken <: AtomicToken

A type of JSON number tokens.
"""
struct NumberToken <: AtomicToken
    value::Real
end

show(io::IO, ::BeginObjectToken) = print(io, "+OB")
show(io::IO, ::EndObjectToken) = print(io, "-OB")
show(io::IO, ::BeginArrayToken) = print(io, "+AR")
show(io::IO, ::EndArrayToken) = print(io, "-AR")
show(io::IO, ::NullToken) = print(io, "=NL: null")
show(io::IO, ::NameSeparatorToken) = print(io, "=NS")
show(io::IO, ::ValueSeparatorToken) = print(io, "=VS")
show(io::IO, x::BooleanToken) = print(io, "=BO: $(x.value)")
show(io::IO, x::StringToken) = print(io, "=ST: $(x.value)")
show(io::IO, x::NumberToken) = print(io, "=NM: $(x.value)")

string(::BeginObjectToken) = string(leftbracechar)
string(::EndObjectToken) = string(rightbracechar)
string(::BeginArrayToken) = string(leftbracketchar)
string(::EndArrayToken) = string(rightbracketchar)
string(::NameSeparatorToken) = string(colonchar)
string(::ValueSeparatorToken) = string(commachar)
string(x::BooleanToken) = string(x.value)
string(::NullToken) = nullstring
string(x::StringToken) = "\"$(x.value)\""
string(x::NumberToken) = x.value

isatomic(x::Token) = x isa AtomicToken
