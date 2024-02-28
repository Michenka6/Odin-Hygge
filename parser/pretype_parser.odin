package parser

import AST "../ast"
import "core:fmt"
/*
    LABEL       := string
    FIELD       := string

    TYPES       :=
                |   EPSILLON
                |   PRETYPE
                |   PRETYPE "," TYPES

    FIELD_TYPES :=
                |   "immutable" FIELD ":" PRETYPE 
                |   FIELD ":" PRETYPE 
                |   FIELD ":" PRETYPE ";" FIELD_TYPES

    UNION_TYPES :=
                |   LABEL ":" PRETYPE 
                |   LABEL ":" PRETYPE ";" UNION_TYPES

    PRETYPE     :=
                |   "(" TYPES ")" "-" ">" PRETYPE
                |   "struct" "{" FIELD_TYPES "}"
                |   "union"  "{" UNION_TYPES "}"
                |   string
*/

parse_pretype :: proc(p: ^Parser) -> (pt: ^AST.Pretype, ok: bool) {
    pt, ok = parse_fun_sign(p)
    if ok { return pt, true }

    pt, ok = parse_union_type(p)
    if ok { return pt, true }

    pt, ok = parse_struct_type(p)
    if ok { return pt, true }

    return parse_single(p)
}

parse_label :: proc(p: ^Parser) -> (s: string, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Ident {
        s = tk.payload.(string)
        p.tk_advanced += 1
        return s, true
    }
    return
}

parse_labels :: proc(p: ^Parser, labels: ^map[string]^AST.Pretype) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Cur { return true }

    label := parse_label(p) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Colon { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    pt := parse_pretype(p) or_return

    labels[label] = pt

    tk = get_tk(p) or_return
    if tk.kind == .Semi_Colon {
        p.tk_advanced += 1
        return parse_labels(p, labels)
    }
    return true 
}

pretype_parse_fields :: proc(p: ^Parser, fields: ^map[string]^AST.Field_Value) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Cur { return true }
    is_mut := true
    if tk.kind == .Immutable { is_mut = false; p.tk_advanced += 1 }
    tk = get_tk(p) or_return

    field := parse_label(p) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Colon { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    pt := parse_pretype(p) or_return

    fv := new(AST.Field_Value)
    fv^ = AST.Field_Value { pt, is_mut }
    fields[field] = fv

    tk = get_tk(p) or_return
    if tk.kind == .Semi_Colon {
        p.tk_advanced += 1
        return pretype_parse_fields(p, fields)
    }
    return true 
}

parse_struct_type :: proc(p: ^Parser) -> (pt: ^AST.Pretype, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind != .Struct { return }
    p.tk_advanced += 1

    tk = get_tk(p) or_return
    if tk.kind != .Left_Cur { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    fields := make(map[string]^AST.Field_Value)
    pretype_parse_fields(p, &fields) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
    p.tk_advanced += 1

    pt = AST.struct_type_make(fields)
    return pt, true
}

parse_union_type :: proc(p: ^Parser) -> (pt: ^AST.Pretype, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind != .Union { return }
    p.tk_advanced += 1

    tk = get_tk(p) or_return
    if tk.kind != .Left_Cur { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    labels := make(map[string]^AST.Pretype)
    parse_labels(p, &labels) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
    p.tk_advanced += 1

    pt = AST.union_type_make(labels)
    return pt, true
}

parse_types :: proc(p: ^Parser, params: ^[dynamic]^AST.Pretype) -> (ok: bool) {
    tk, got_tk := get_tk(p)
    if !got_tk { return }

    if tk.kind == .Right_Par { return true }

    pt := parse_pretype(p) or_return
    append_elem(params, pt)

    tk, got_tk = get_tk(p)
    if got_tk && tk.kind == .Comma {
         p.tk_advanced += 1
         return parse_types(p, params)
    }
    return true
}

parse_fun_sign :: proc(p: ^Parser) -> (pt: ^AST.Pretype, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind != .Left_Par { return }
    p.tk_advanced += 1

    params := make([dynamic]^AST.Pretype)
    parse_types(p, &params) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Right_Par { return }
    p.tk_advanced += 1

    tk = get_tk(p) or_return
    if tk.kind != .Minus { return }
    p.tk_advanced += 1

    tk = get_tk(p) or_return
    if tk.kind != .Greater { return }
    p.tk_advanced += 1

    res := parse_pretype(p) or_return

    pt = AST.fun_sign_make(params, res)

    return pt, true
}

parse_single :: proc(p: ^Parser) -> (pt: ^AST.Pretype, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind != .Ident { return }
    p.tk_advanced += 1
    pt = AST.single_make(tk.payload.(string))
    return pt, true
}
