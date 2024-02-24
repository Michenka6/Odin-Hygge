package ast

Position :: struct {
    column: u64,
    line:   u64,
}

Single :: struct {
    t: string,
}

Fun_Sign :: struct {
    params: [dynamic]^Pretype,
    res:   ^Pretype,
}

Struct_Type :: struct {
    fields: map[string]^Pretype,
}

Union_Type :: struct {
    labels: map[string]^Pretype,
}

Pretype :: union {
    Single,
    Fun_Sign,
    Struct_Type,
    Union_Type,
}

Node :: struct {
    pos:   Position,
    expr: ^Expr,
}

Expr :: union {
    Sequence,
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

Fun_App :: struct {
    fun_name: string,
    params:   [dynamic]^Node,
}

Match_Pattern :: struct {
    label: string,
    var:   string,
}

Match_Case :: struct {
    e1:      ^Node,
    patterns: map[Match_Pattern]^Node,
}

Union_Constructor :: struct {
    label: string,
    e1:   ^Node,
}

Struct :: struct {
    fields: map[string]^Node,
}

While :: struct {
    e1: ^Node,
    e2: ^Node,
}

Type_Decl :: struct {
    x:   string,
    pt: ^Pretype,
    e1: ^Node,
}

Let :: struct {
    is_mut: bool,
    x:      string,
    pt:    ^Pretype,
    e1:    ^Node,
    e2:    ^Node,
}

Sequence :: struct {
    e1: ^Node,
    e2: ^Node,
}

If_Else :: struct {
    e1: ^Node,
    e2: ^Node,
    e3: ^Node,
}

Assignment :: struct {
    x:   string,
    e1: ^Node,
}

Unary_Op :: enum {
    U_Minus,
    Sqrt,
    Not,
    Print,
    Println,
    Assert,
    Read_Int,
    Read_Float,
}

Unary_Fun :: struct {
    op:  Unary_Op,
    e1: ^Node,
}

Binary_Op :: enum {
    Modulus,
    Divide,
    Times,
    Plus,
    Minus,
    Max,
    Min,
    Less,
    Greater,
    Less_Equals,
    Greater_Equals,
    Equals,
    Or,
    And,
}

Binary_Fun :: struct {
    op:  Binary_Op,
    e1: ^Node,
    e2: ^Node,
}

Variable :: struct {
    x: string,
}

Field_Access :: struct {
    x:     string,
    field: string
}

Value_Type :: enum {
    Int,
    Bool,
    String,
    Float,
    Unit,
}

Value_Payload :: union {
    int,
    f64,
    bool,
    string,
}

Value :: struct {
    type: Value_Type,
    v: Value_Payload,
}

Parens :: struct {
    e1: ^Node,
}

Scope :: struct {
    e1: ^Node,
}