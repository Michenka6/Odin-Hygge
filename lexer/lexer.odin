package lexer

import "../ast"

import "core:strings"
import "core:fmt"
import "core:math"

Lexer :: struct {
    using pos: Position,
    cursor:     u64,
    data:       []u8,
    tokens:     [dynamic]Token,
}

Position :: ast.Position

Payload :: union {
    int,
    f64,
    string,
    bool,
}

Token :: struct {
    using pos: Position,
    kind:     Token_Kind,
    payload:  Payload,  // nil union case, means unit
}

Token_Kind :: enum {
    Invalid,
    Eof,
    // Value types
    Int,
    Boolean,
    String_Lit,
    Float,
    Ident,
    // Built-in functions
    Read_Int,
    Read_Float,
    Assert,
    Print,
    PrintLn,
    // Reserved Chars
    Plus,
    Minus,
    Times,
    Div,
    Mod,
    Left_Par,
    Right_Par,
    Left_Cur,
    Right_Cur,
    Eq,
    Less,
    Greater,
    Colon,
    Semi_Colon,
    Comma,
    Period,
    // Reserved Idents
    True,
    False,
    Let,
    Type,
    If,
    Then,
    Else,
    And,
    Or,
    Not,
    Sqrt,
    Mutable,
    Min,
    Max,
    Union,
    Match,
    With,
    Fun,
    While,
    Do,
    Struct,
    For,
}

lexer_make :: proc(data: []u8) -> (l: ^Lexer) {
    l            = new(Lexer)
    l.data       = data
    l.pos = Position { 1, 1 }
    l.tokens     = make([dynamic]Token)
    return
}

lexer_delete :: proc(l: ^Lexer) { 
    delete(l.tokens); 
    free(l)
}

tokenize :: proc(l: ^Lexer) {
    tk := next_token(l)
    for tk.kind != .Eof {
        // print_token(tk)
        append_elem(&l.tokens, tk)
        tk = next_token(l)
    }
}

print_token :: proc(tk: Token) {
    fmt.printf("\t(%i:%i) %v [ Payload = %v ]\n", tk.line, tk.column, tk.kind, tk.payload)
}

reserved_chars := map[u8]Token_Kind {
    '+' = .Plus,
    '-' = .Minus,     
    '*' = .Times,
    '/' = .Div,
    '%' = .Mod,
    '{' = .Left_Cur,
    '}' = .Right_Cur,
    '(' = .Left_Par,
    ')' = .Right_Par,
    '=' = .Eq,
    '<' = .Less,
    '>' = .Greater,
    ':' = .Colon,
    ';' = .Semi_Colon,
    ',' = .Comma,
    '.' = .Period,
}

next_token :: proc(l: ^Lexer) -> (tk: Token) {
    c, ok := peek(l)
    if !ok { tk.kind = .Eof; return}

    skip_whitespace(l)
    c, ok = peek(l)
    if !ok { tk.kind = .Eof; return}

    skip_comment(l)
    c, ok = peek(l)
    if !ok { tk.kind = .Eof; return}

    if c in reserved_chars {
        tk.pos = l.pos
        l.column += 1
        l.cursor += 1
        tk.kind = reserved_chars[c]
        return
    }


    tk, ok = parse_float(l)
    if ok { return }

    tk, ok = parse_string_lit(l)
    if ok { return }

    tk, ok = parse_ident(l)
    if ok {
        switch tk.payload.(string) {
            case "true":        tk.kind = .True
            case "false":       tk.kind = .False
            case "let":         tk.kind = .Let
            case "type":        tk.kind = .Type
            case "if":          tk.kind = .If
            case "then":        tk.kind = .Then
            case "else":        tk.kind = .Else
            case "and":         tk.kind = .And
            case "or":          tk.kind = .Or
            case "not":         tk.kind = .Not
            case "sqrt":        tk.kind = .Sqrt
            case "readInt":     tk.kind = .Read_Int
            case "readFloat":   tk.kind = .Read_Float
            case "print":       tk.kind = .Print
            case "println":     tk.kind = .PrintLn
            case "assert":      tk.kind = .Assert
            case "mutable":     tk.kind = .Mutable
            case "min":         tk.kind = .Min
            case "max":         tk.kind = .Max
            case "union":       tk.kind = .Union
            case "match":       tk.kind = .Match
            case "with":        tk.kind = .With
            case "fun":         tk.kind = .Fun
            case "while":       tk.kind = .While
            case "struct":      tk.kind = .Struct
            case "do":          tk.kind = .Do
            case "for":         tk.kind = .For
        }
    }
    
    l.cursor += 1
    l.column += 1
    return 
}

skip_whitespace :: proc(l: ^Lexer) {
    // fmt.println("Skipping Whitespace")
    c, ok := peek(l)
    if !ok { return }
    switch c {
        case '\n':  l.cursor += 1; l.column  = 1;   l.line  += 1
        case '\r':  l.cursor += 1; l.column += 1
        case '\t':  l.cursor += 1; l.column += 4
        case ' ':   l.cursor += 1; l.column += 1
        case:       return
    }
    skip_whitespace(l)
}

skip_comment :: proc(l: ^Lexer) {
    // fmt.println("Skipping Comments")
    c, ok := peek(l)
    if !ok || c != '/' { return }
    l.cursor += 1
    l.column += 1

    c, ok = peek(l)
    if !ok || c != '/' { 
        l.cursor -= 1
        l.column -= 1
        return
    }
    l.cursor += 1
    l.column += 1

    c, ok = peek(l)
    for ok && c != '\n' {
        l.cursor += 1
        l.column += 1
        c, ok = peek(l)
    }
    l.cursor += 1
    l.column  = 1
    l.line   += 1
    skip_whitespace(l)
    skip_comment(l)
}

parse_string_lit  :: proc(l: ^Lexer) -> (tk: Token, ok: bool) {
    // fmt.println("Parsing string literal")
    c := peek(l) or_return
    if c != '"' { return }
    tk.kind = .String_Lit
    tk.pos = l.pos
    l.column += 1
    l.cursor += 1

    c, ok = peek(l)
    start := l.cursor
    end   := l.cursor
    for ok && c != '"' {
        l.column += 1
        l.cursor += 1
        end += 1
        c, ok = peek(l)
    }
    l.column += 1
    l.cursor += 1
    tk.payload = string(l.data[start:end])
    return tk, true
}

parse_ident  :: proc(l: ^Lexer) -> (tk: Token, ok: bool) {
    tk.pos = l.pos
    tk.kind = .Ident
    c := peek(l) or_return
    if !is_alphanum(c) { return }

    start := l.cursor
    end   := l.cursor + 1
    l.cursor += 1
    l.column += 1

    c, ok = peek(l)
    for ok && (is_alphanum(c) || is_digit(c)) {
        end += 1
        l.cursor += 1
        l.column += 1
        c, ok = peek(l)
    }
    tk.payload = string(l.data[start:end])
    l.column -= 1
    l.cursor -= 1
    return tk, true
}

is_alphanum :: proc(c: u8) -> bool {
    switch c {
        case 'a'..='z': fallthrough
        case 'A'..='Z': fallthrough
        case '0'..='9': fallthrough
        case '_':       return true
    }
    return false
}

is_digit :: proc(c: u8) -> bool {
    switch c { case '0'..='9': return true }
    return false
}

parse_float :: proc(l: ^Lexer) -> (tk: Token, ok: bool) {
    pos := l.pos
    cursor := l.cursor

    tk = parse_int(l) or_return

    v1 := tk.payload.(int)
    c, got_c := peek(l)
    if got_c && c == '.' {
        l.cursor += 1
        l.column += 1
        tk = parse_int(l) or_return
        v2 := tk.payload.(int)

        tk.kind = .Float
        tk.payload = float_from_two_ints(v1, v2)
        tk.pos = pos
        l.cursor += 1
    }
    return tk, true
}

parse_int :: proc(l: ^Lexer) -> (tk: Token, ok: bool) {
    // fmt.println("Parsing int")
    c := peek(l) or_return
    if is_digit(c) {
        tk.kind = .Int
        tk.pos = l.pos
        tk.payload = int(c - '0')

        l.column += 1
        l.cursor += 1
        c, ok = peek(l)
        for ok && is_digit(c) {
            tk.payload = tk.payload.(int) *10 + int(c - '0')
            l.column += 1
            l.cursor += 1
            c, ok = peek(l)
        }
        return tk, true
    }
    return
}

peek :: proc(using l: ^Lexer) -> (u8, bool) {
    if l.cursor < u64(len(data)) { return data[cursor], true }
    return 0x69, false
}

float_from_two_ints := proc(whole: int, fractional: int) -> f64 {
    fractional_part := f64(fractional) / math.pow(10.0, f64(len(fmt.aprintf("%d", fractional))));

    return f64(whole) + fractional_part;
}
