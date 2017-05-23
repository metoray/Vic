import nre
import typetraits
import strutils

type
    TokenKind* = enum
        tkUnknown
        tkEOF
        tkWhitespace
        tkIdentifier
        tkNumber
        tkFunctionKW
        tkIfKW
        tkElseKW
        tkElseIfKW
        tkThisKW
        tkOpenParen
        tkCloseParen
        tkComma
        tkColon
        tkEquals
        tkAssign
        tkNewLine
        tkOperator
        tkGate

    Token* = ref object of RootObj
        case kind*: TokenKind
        of tkIdentifier: name*: string
        of tkNumber: number*: string
        of tkWhitespace: len*: int
        of tkOperator: op*: char
        else: discard

    TokenParser = tuple
        pattern: Regex
        factory: proc(match: RegexMatch): Token

proc `$`*(token: Token): string =
    result = case token.kind
    of tkIdentifier: "$#($#)" % [$token.kind, token.name]
    of tkWhitespace: "$#($#)" % [$token.kind, $token.len]
    of tkOperator: "$#($#)" % [$token.kind, $token.op]
    of tkNumber: "$#($#)" % [$token.kind, $token.number]
    else: $token.kind

proc len(slice: Slice): int = slice.b - slice.a + 1

let tokenlist: seq[TokenParser] = @[
    (
        re"([a-zA-Z_][a-zA-Z0-9_]*)",
        proc(match: RegexMatch) : Token{.closure.} =
            result = case match.captures[0]
            of "function": Token(kind: tkFunctionKW)
            of "if": Token(kind: tkIfKW)
            of "else": Token(kind: tkElseKW)
            of "elseif": Token(kind: tkElseIfKW)
            of "this": Token(kind: tkThisKW)
            else: Token(kind: tkIdentifier, name: match.captures[0])
    ),
    (
        re"([0-9][a-zA-Z0-9_]*)",
        proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkNumber, number: match.captures[0])
    ),
    (
        re" +", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkWhitespace, len: match.matchbounds.len)
    ),
    (
        re"\\\n", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkWhitespace, len: match.matchbounds.len)
    ),
    (
        re"[\n;]", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkNewLine)
    ),
    (
        re"\(", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkOpenParen)
    ),
    (
        re"\)", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkCloseParen)
    ),
    (
        re",", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkComma)
    ),
    (
        re":", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkColon)
    ),
    (
        re"==", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkEquals)
    ),
    (
        re"=", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkAssign)
    ),
    (
        re"#", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkGate)
    ),
    (
        re"([\+\-\/\*%])", proc(match: RegexMatch) : Token{.closure.} =
            Token(kind: tkOperator, op: match.captures[0][0])
    ),
]

proc firstToken(s: var string): tuple[token: Token, slice: Slice[int]] =
    var token = Token(kind: tkUnknown)
    var slice: Slice[int] = Slice[int](a:0, b:0)
    if s == "":
        token = Token(kind: tkEOF)
        return (token, slice)
    for parser in tokenlist:
        let match = s.match(parser.pattern)
        if match.isSome:
            token = parser.factory(match.get)
            slice = match.get.matchbounds
            break
    return (token, slice)

proc popToken(s: var string): Token =
    var foundToken = s.firstToken
    s.delete(foundToken.slice.a, foundToken.slice.b)
    return foundToken.token

proc getTokens*(s: var string): seq[Token] =
    result = @[]

    while true:
        var t = s.popToken
        result.add(t)
        if t.kind == tkEOF:
            break

