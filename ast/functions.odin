package ast

single_make :: proc(s: string) -> (pt: ^Pretype) {
    pt = new(Pretype)
    pt^ = Single { s }
    return
}

fun_sign_make :: proc(params: [dynamic]^Pretype, res: ^Pretype) -> (pt: ^Pretype) {
    pt = new(Pretype)
    pt^ = Fun_Sign { params, res }
    return
}

union_type_make :: proc(labels: map[string]^Pretype) -> (pt: ^Pretype) {
    pt = new(Pretype)
    pt^ = Union_Type { labels }
    return
}

struct_type_make :: proc(fields: map[string]^Pretype) -> (pt: ^Pretype) {
    pt = new(Pretype)
    pt^ = Struct_Type { fields }
    return
}

sequence_make :: proc(e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Sequence { e1, e2 }
    return
}

type_ascription_make :: proc(e1: ^Expr, pt: ^Pretype) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Type_Ascription { e1, pt }
    return
}

fun_decl_make :: proc(params: map[string]^Pretype, e1: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Fun_Decl { params, e1 }
    return
}

fun_app_make :: proc(fun_name: string, params: [dynamic]^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Fun_App { fun_name, params }
    return
}

match_cases_make :: proc(e1: ^Expr, patterns: map[Match_Pattern]^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Match_Case { e1, patterns }
    return
}

union_constructor_make :: proc(label: string, e1: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Union_Constructor { label, e1 }
    return
}

struct_make :: proc(fields: map[string]^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Struct { fields }
    return
}

while_make :: proc(e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = While { e1, e2 }
    return
}

type_decl_make :: proc(x: string, pt: ^Pretype, e1: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Type_Decl { x, pt, e1 }
    return
}

let_make :: proc(is_mut: bool, x: string, pt: ^Pretype, e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Let { is_mut, x, pt, e1, e2 }
    return
}

if_else_make :: proc(e1: ^Expr, e2: ^Expr, e3: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = If_Else { e1, e2, e3 }
    return
}

assignment_make :: proc(x: string, e1: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Assignment { x, e1 }
    return
}

unary_make :: proc(op: Unary_Op, e1: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Unary_Fun { op, e1 }
    return
}

binary_make :: proc(op: Binary_Op, e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Binary_Fun { op, e1, e2 }
    return
}

variable_make :: proc(x: string) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Variable { x }
    return
}

field_access_make :: proc(x: string, field: string) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Field_Access { x, field }
    return
}

value_make :: proc (type: Value_Type, v: Value_Payload) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Value { type, v }
    return
}

parens_make :: proc (e1: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Parens { e1 }
    return
}

scope_make :: proc (e1: ^Expr) -> (expr: ^Expr) {
    expr  = new(Expr)
    expr^ = Scope { e1 }
    return
}