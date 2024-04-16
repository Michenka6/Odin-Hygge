package ast

import "core:fmt"

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

struct_type_make :: proc(fields: map[string]^Field_Value) -> (pt: ^Pretype) {
    pt = new(Pretype)
    pt^ = Struct_Type { fields }
    return
}

expr_make :: proc() -> (expr: ^Expr) {
    expr = new(Expr)
    expr.variance = new(Expr_Variance)
    return expr
}

sequence_make :: proc(e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Sequence { e1, e2 }
    return
}

type_ascription_make :: proc(e1: ^Expr, pt: ^Pretype) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Type_Ascription { e1, pt }
    return
}

fun_decl_make :: proc(params: map[string]^Pretype, e1: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Fun_Decl { params, e1 }
    return
}

fun_app_make :: proc(fun: string, params: [dynamic]^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Fun_App { fun, params }
    return
}

match_cases_make :: proc(e1: ^Expr, patterns: map[Match_Pattern]^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Match_Case { e1, patterns }
    return
}

union_constructor_make :: proc(label: string, e1: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Union_Constructor { label, e1 }
    return
}

struct_make :: proc(fields: map[string]^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Struct { fields }
    return
}

while_make :: proc(e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = While { e1, e2 }
    return
}

type_decl_make :: proc(x: string, pt: ^Pretype, e1: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Type_Decl { x, pt, e1 }
    return
}

let_make :: proc(is_mut: bool, x: string, pt: ^Pretype, e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Let { is_mut, x, pt, e1, e2 }
    return
}

if_else_make :: proc(e1: ^Expr, e2: ^Expr, e3: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = If_Else { e1, e2, e3 }
    return
}

assignment_make :: proc(e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Assignment { e1, e2 }
    return
}

unary_make :: proc(op: Unary_Op, e1: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Unary_Fun { op, e1 }
    return
}

binary_make :: proc(op: Binary_Op, e1: ^Expr, e2: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Binary_Fun { op, e1, e2 }
    return
}

variable_make :: proc(x: string) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Variable { x }
    return
}

field_access_make :: proc(e1: ^Expr, field: string) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Field_Access { e1, field }
    return
}

value_make :: proc (type: Value_Type, v: Value_Payload) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Value { type, v }
    return
}

parens_make :: proc (e1: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Parens { e1 }
    return
}

scope_make :: proc (e1: ^Expr) -> (expr: ^Expr) {
    expr  = expr_make()
    expr.variance^ = Scope { e1 }
    return
}

expr_subst :: proc(var: string, new_expr: ^Expr, expr: ^Expr) {
    if expr == nil || new_expr == nil { return }

    switch e in expr.variance {
	case Sequence:
	    expr_subst(var, new_expr, e.e1)
	    expr_subst(var, new_expr, e.e2)
	case Type_Ascription:
	    expr_subst(var, new_expr, e.e1)
	case Let:
	    expr_subst(var, new_expr, e.e1)
	    if e.x != var { expr_subst(var, new_expr, e.e2) }
	case Fun_Decl:
	    for k,v in e.params { if k == var { return } }
	    expr_subst(var, new_expr, e.e1)
	case Fun_App:
	    // if e.fun == var { e.fun = var }
	    for p in e.params { expr_subst(var, new_expr, p) }
	case Match_Case:
	case Union_Constructor:
	case Struct:
	    for _,v in e.fields { expr_subst(var, new_expr, v) }
	case While:
	    expr_subst(var, new_expr, e.e1)
	    expr_subst(var, new_expr, e.e2)
	case Type_Decl:
	    expr_subst(var, new_expr, e.e1)
	case If_Else:
	    expr_subst(var, new_expr, e.e1)
	    expr_subst(var, new_expr, e.e2)
	    expr_subst(var, new_expr, e.e3)
	case Assignment:
	    expr_subst(var, new_expr, e.e1)
	    expr_subst(var, new_expr, e.e2)
	case Unary_Fun:
	    expr_subst(var, new_expr, e.e1)
	case Binary_Fun:
	    expr_subst(var, new_expr, e.e1)
	    expr_subst(var, new_expr, e.e2)
	case Variable:		    if e.x == var { expr^ = new_expr^ }
	case Field_Access:
	    expr_subst(var, new_expr, e.e1)
	case Value:
	case Parens:		    expr_subst(var, new_expr, e.e1)
	case Scope:		    expr_subst(var, new_expr, e.e1)
    }
    return
}

// propogate_pretype_subst :: proc(var: string, new_pt: ^Pretype, expr: ^Expr) {
//     if expr == nil { return }
//
//     switch e in expr {
// 	case Sequence:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    propogate_pretype_subst(var, new_pt, e.e2)
// 	case Type_Ascription:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    pretype_subst(var, new_pt, e.pt)
// 	case Let:
// 	    pretype_subst(var, new_pt, e.pt)
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    propogate_pretype_subst(var, new_pt, e.e2)
// 	case Fun_Decl:
// 	    for k,v in e.params { pretype_subst(var, new_pt, v) }
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	case Fun_App:
// 	    propogate_pretype_subst(var, new_pt, e.fun)
// 	    for p in e.params { propogate_pretype_subst(var, new_pt, p) }
// 	case Match_Case:
// 	case Union_Constructor:
// 	case Struct:
// 	    for _,v in e.fields { propogate_pretype_subst(var, new_pt, v) }
// 	case While:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    propogate_pretype_subst(var, new_pt, e.e2)
// 	case Type_Decl:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    propogate_pretype_subst(e.x, e.pt, e.e1)
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    expr.variance^ = e.e1^
// 	case If_Else:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    propogate_pretype_subst(var, new_pt, e.e2)
// 	    propogate_pretype_subst(var, new_pt, e.e3)
// 	case Assignment:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    propogate_pretype_subst(var, new_pt, e.e2)
// 	case Unary_Fun:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	case Binary_Fun:
// 	    propogate_pretype_subst(var, new_pt, e.e1)
// 	    propogate_pretype_subst(var, new_pt, e.e2)
// 	case Variable:
// 	case Field_Access:
// 	case Value:
// 	case Parens:		    propogate_pretype_subst(var, new_pt, e.e1)
// 	case Scope:		    propogate_pretype_subst(var, new_pt, e.e1)
//     }
//     return
// }
//
// pretype_subst :: proc(t: string, new_pt: ^Pretype, pt: ^Pretype) {
//     if pt == nil || new_pt == nil { return }
//     switch p in pt {
//         case Single:
// 	    if p.t == t { pt^ = pretype_clone(new_pt)^ }
//         case Fun_Sign:
// 	    for param in p.params { pretype_subst(t, new_pt, param) }
// 	    pretype_subst(t, new_pt, p.res)
//         case Struct_Type:
// 	    for k,v in p.fields { pretype_subst(t, new_pt, v.pt) }
//         case Union_Type:
// 	    for k,v in p.labels { pretype_subst(t, new_pt, v) }
//     }
// }

pretype_clone :: proc(pt: ^Pretype) -> (new_pt: ^Pretype) {
    if pt == nil { return }

    new_pt = new(Pretype)
    switch p in pt {
	case Single:
	    new_pt^ = Single { p.t }
        case Fun_Sign:
	    params := make([dynamic]^Pretype)
	    for param in p.params { append_elem(&params, pretype_clone(param)) }
	    res := pretype_clone(p.res)
	    new_pt^ = Fun_Sign { params, res }
	case Struct_Type:
	    fields := make(map[string]^Field_Value)
	    for k,v in p.fields {
		field_value := new(Field_Value)
		field_value^ = Field_Value { pretype_clone(v.pt), v.is_mut }
		fields[k] = field_value
	    }
	    new_pt^ = Struct_Type { fields }
        case Union_Type:
	    labels := make(map[string]^Pretype)
	    for k,v in p.labels { labels[k] = pretype_clone(v) }
	    new_pt^ = Union_Type { labels }
    }
    return
}

expr_clone :: proc(expr: ^Expr) -> (new_expr: ^Expr) {
    if expr == nil { return }
    switch e in expr.variance {
	case Sequence:
	    e1 := expr_clone(e.e1)
	    e2 := expr_clone(e.e2)
	    new_expr = sequence_make(e1, e2)
	case Type_Ascription:
	    e1 := expr_clone(e.e1)
	    pt := pretype_clone(e.pt)
	    new_expr = type_ascription_make(e1, pt)
	case Let:
	    e1 := expr_clone(e.e1)
	    e2 := expr_clone(e.e2)
	    pt := pretype_clone(e.pt)
	    new_expr = let_make(e.is_mut, e.x, pt, e1, e2)
	case Fun_Decl:
	    params := make(map[string]^Pretype)
	    for k,v in e.params { params[k] = pretype_clone(v) }
	    e1 := expr_clone(e.e1)
	    new_expr = fun_decl_make(params, e1)
	case Fun_App:
	    params := make([dynamic]^Expr)
	    for param in e.params { append_elem(&params, expr_clone(param)) }
	    new_expr = fun_app_make(e.fun, params)
	case Match_Case:
	    e1 := expr_clone(e.e1)
	    patterns := make(map[Match_Pattern]^Expr)
	    for k,v in e.patterns { patterns[k] = expr_clone(v) }
	    new_expr = match_cases_make(e1, patterns)
	case Union_Constructor:
	    e1 := expr_clone(e.e1)
	    new_expr = union_constructor_make(e.label, e1)
	case Struct:
	    fields := make(map[string]^Expr)
	    for k,v in e.fields { fields[k] = expr_clone(v) }
	    new_expr = struct_make(fields)
	case While:
	    e1 := expr_clone(e.e1)
	    e2 := expr_clone(e.e2)
	    new_expr = while_make(e1, e2)
	case Type_Decl:
	    e1 := expr_clone(e.e1)
	    pt := pretype_clone(e.pt)
	    new_expr = type_decl_make(e.x, pt, e1)
	case If_Else:
	    e1 := expr_clone(e.e1)
	    e2 := expr_clone(e.e2)
	    e3 := expr_clone(e.e3)
	    new_expr = if_else_make(e1, e2, e3)
	case Assignment:
	    e1 := expr_clone(e.e1)
	    e2 := expr_clone(e.e2)
	    new_expr = assignment_make(e1, e2)
	case Unary_Fun:
	    e1 := expr_clone(e.e1)
	    new_expr = unary_make(e.op, e1)
	case Binary_Fun:
	    e1 := expr_clone(e.e1)
	    e2 := expr_clone(e.e2)
	    new_expr = binary_make(e.op, e1, e2)
	case Variable:
	    new_expr = variable_make(e.x)
	case Field_Access:
	    new_expr = field_access_make(e.e1, e.field)
	case Value:
	    new_expr = value_make(e.type, e.v)
	case Parens:
	    new_expr = parens_make(e.e1)
	case Scope:
	    new_expr = scope_make(e.e1)
    }
    return
}
