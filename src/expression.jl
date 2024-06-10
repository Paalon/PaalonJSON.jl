import Base: push!, setindex!

struct NotConvertibleToJSONError <: Exception
    msg::String
end

"""
    JSONValue

An abstract type represents a JSON value.

Children types are required to implement:

* dump(x::JSONValue)
* print(io::IO, x::JSONValue)
"""
abstract type JSONValue end

function print(io::IO, x)
    if x isa AbstractArray
        print(io, JSONArray(x))
    elseif x isa AbstractDict
        print(io, JSONObject(x))
    elseif x isa Nothing
        print(io, JSONNull())
    elseif x isa Bool
        print(io, JSONBoolean(x))
    elseif x isa AbstractString
        print(io, JSONString(x))
    elseif x isa Real
        print(io, JSONNumber(x))
    else
        throw(NotConvertibleToJSONError("cannot convert to a JSON expression."))
    end
end

"""
    JSONObject <: JSONValue

A type for a JSON object.
"""
mutable struct JSONObject <: JSONValue
    value::Dict{String, Any}
end

JSONObject() = JSONObject(Dict{String, Any}())

dump(object::JSONObject) = object.value

function print(io::IO, object::JSONObject)
    d = dump(object)
    n = length(d)
    i = 0
    Base.print(io, '{')
    for (key, value) in d
        i += 1
        print(io, JSONString(key))
        Base.print(io, ':')
        print(io, value)
        if i == n
        else
            Base.print(io, ',')
        end
    end
    Base.print(io, '}')
end

setindex!(object::JSONObject, value, key) = setindex!(object.value, value, key)

"""
    JSONArray <: JSONValue

A type for a JSON array.
"""
mutable struct JSONArray <: JSONValue
    value::Vector
end

JSONArray() = JSONArray([])

dump(array::JSONArray) = array.value

function print(io::IO, array::JSONArray)
    xs = dump(array)
    n = length(xs)
    Base.print(io, '[')
    for (i, x) in enumerate(xs)
        print(io, x)
        if i == n
        else
            Base.print(io, ',')
        end
    end
    Base.print(io, ']')
end

push!(array::JSONArray, items...) = push!(array.value, items...)

"""
    JSONNull <: JSONValue

A type for a JSON null.
"""
struct JSONNull <: JSONValue end

dump(::JSONNull) = nothing

print(io::IO, ::JSONNull) = Base.print(io, "null")

"""
    JSONBoolean <: JSONValue

A type for a JSON boolean.
"""
struct JSONBoolean <: JSONValue
    value::Bool
end

dump(b::JSONBoolean) = b.value

print(io::IO, b::JSONBoolean) = Base.print(io, dump(b))

"""
    JSONString <: JSONValue

A type for a JSON string.
"""
struct JSONString <: JSONValue
    value::String
end

dump(str::JSONString) = str.value

print(io::IO, s::JSONString) = Base.print(io, '"', dump(s), '"')

"""
    JSONNumber <: JSONValue

A type for a JSON number.
"""
struct JSONNumber <: JSONValue
    value::Real
end

dump(n::JSONNumber) = n.value

print(io::IO, n::JSONNumber) = Base.print(io, dump(n))
