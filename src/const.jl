const leftbracechar = '{'
const rightbracechar = '}'
const leftbracketchar = '['
const rightbracketchar = ']'
const colonchar = ':'
const commachar = ','
const quotationmarkchar = '"'
const nullstring = "null"
const truestring = "true"
const falsestring = "false"

# whitespaces

const space = ' '
const horizontaltab = '\t'
const linefeedornewline = '\n'
const carriagereturn = '\r'

"""
    iswhitespace(c::AbstractChar) -> Bool

Test whether a character is a JSON whitespace.
"""
iswhitespace(c::AbstractChar) = c == space || c == horizontaltab || c == linefeedornewline || c == carriagereturn

issymbol(c::AbstractChar) = c == colonchar || c == commachar || c == leftbracechar || c == rightbracechar || c == leftbracketchar || c == rightbracketchar || c == quotationmarkchar
isseparator(c::AbstractChar) = iswhitespace(c) || issymbol(c)
