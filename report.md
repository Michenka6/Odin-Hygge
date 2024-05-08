***02247 Compiler Construction Project Report***

***Custom Project 2***

***S204743 - Amirkhon Alimov***

# Contents


- [AST](#ast)
    - [High-level idea](#high-level-idea)
    - [Odin implementation](#odin-implementation)
- [Lexing/Parsing](#lexing/parsing)
    - [Lexing](#lexing)
    - [Parsing](#parsing)
- [Typechecking](#typechecking)
- [Intermideate Representation](#intermideate-representation)
- [Code Generation](#code-generation)

# AST

## High-level idea
Hygge is an expression based language, meaning every program is a single expression which can contain one or more expressions.
Therefore, the easiest and simplemest representation for the structure of an expression would be tree, which recursively refers to other `Tree<Expr>`.
In the original hyggec compiler provided, an Expr is a discriminated union of different cases of expressions, which have unique constructors and carry data.

## Odin implementation
Unlike F#, Odin is a manually managed memory language, so the idea of the AST structure is different, but similar conceptually.

Each expr is just a struct of two fields `type` and `variance`, type reflects an internal compiler type that will be assigned during the typechecking stage, while variance is a C-like union of structs as follows:
```odin
Expr :: struct {
    type:     ^T,
    variance: ^Expr_Variance,
}
Expr_Variance :: union {
    Sequence,
    Type_Ascription,
    Fun_Decl,
    Fun_App,
    Match_Case,
    Union_Constructor,
    Struct,
    While,
    Type_Decl,
    Let,
    If_Else,
    Assignment,
    Unary_Fun,
    Binary_Fun,
    Variable,
    Field_Access,
    Value,
    Parens,
    Scope,
}
```

Further details about the memory layout, initialization and cleaning up memory are irrelevant and outside the scope of this project, but the reader is welcomed to explore the code base.
What's important, is that each `variance` of an expression may contain pointers to different `Expr`, thus expressing recursivity as follows:
```odin
Sequence :: struct {
    e1: ^Expr,
    e2: ^Expr,
}
```

# Lexing/Parsing

## Lexing
Lexer passes through a stream of characters and emits/stores tokens which will be used by a parser.
Lexing is extremelly trivial so the following structure should be self-explanatory:
```odin
Lexer :: struct {
    using pos:  Position,
    cursor:     u64,
    data:       []u8,
    tokens:     [dynamic]Token,
}
```
*`[dynamic]Token`, just means a dynamic array of Tokens*

## Parsing
This project implements an optimized top-down recursive descent parser:
```odin
Parser :: struct {
    cursor      : u64,
    tk_advanced : u64,
    tokens      : [dynamic]Lexer.Token,
}
```

It uses the following Context-Free Grammar, where `ME` is the first rule to match:
```
    ME  ::= AE ( ";" AE )*
    AE  ::= TE ( ( "<-" + "-=" + "*=" + "/=" + "%=" ) TE )?
    TE  ::=
        |   E ( ":" PRETYPE )?
    E   ::=
        |   "readInt"   "("   ")"
        |   "readFloat" "("   ")"
        |   "print"     "(" AE ")"
        |   "println"   "(" AE ")"
        |   "assert"    "(" AE ")"
        |   "if" D
        |   "let" C
        |   "type" F
        |   "while" B "do" E
        |   "do" AE "while" B
        |   "for" G
        |   "struct" "{" H "}"
        |   "fun" K
        |   B
        |   A
    C   ::=
        |   ( "mutable" )? IDENT ":" PRETYPE "=" AE ";" AE
    D   ::=
        |   B "then" AE "else" AE
    F   ::=
        |   IDENT "=" PRETYPE ";" AE
    G   ::=
        |   "(" AE "," B "," AE ")" AE
    H   ::=
        |   HH ( ";" HH)*
    HH  ::=
        |   ( IDENT "=" AE )?
    K   ::=
        |   "(" L ")" "-" ">" AE
        |   IDENT "(" L ")" ":" PRETYPE "=" AE ";" AE
    L   ::=
        |   ( IDENT ":" PRETYPE ( "," L )* )?
```






# Typechecking








- [x] $e_{1} / e_{2}$     arithmetic operation
- [x] $e_{1}\ \%\ e_{2}$     arithmetic operation
- [x] $sqrt(e)$     arithmetic operation
- [x] $max(e_{1},\ e_{2})$ arithmetic operation
- [x] $min(e_{1},\ e_{2})$ arithmetic operation
***
- [x] $e_{1} <= e_{2}$ relational operation
- [x] $e_{1} > e_{2}$  relational operation
- [x] $e_{1} >= e_{2}$ relational operation
***
- [x] $e_{1}\ xor\ e_{2}$ relational operation
***
- [ ] $++x$ C-style post-increments
- [ ] $x++$ C-style pre-increments
- [ ] $x--$ C-style post-decrement
- [ ] $--x$ C-style pre-decrements
***
- [x] $x\ +=\ e$ C-style add-assign
- [x] $x\ -=\ e$ C-style minus-assign
- [x] $x\ *=\ e$ C-style times-assign
- [x] $x\ /=\ e$ C-style divide-assign
***
- [x] "Do..While" Loop
***
- [x] "For" Loop
- [x] $e_{1}\ sand\ e_{2}$ short-circuit and
- [x] $e_{1}\ sor\ e_{2}$  short-circuit or

- [x] Mutable vs Immutable struct fields
- [x] Recursive Functions
***
- [x] Improved implementation of the RISC-V Calling Convention: pass more that 8 arguments through the stack

# Intermideate Representation













# Code Generation
