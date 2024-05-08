package ast

import "core:fmt"

/*
COLOR PALLET:
    33  -   Expression keywords
    92  -   Field names
    93  -   Value literals
    94  -   Pretype keywords
    95  -   Function name
*/

value_to_string :: proc(v: Value_Payload) -> (s: string) {
    if v == nil { return "\033[93m()\033[0m" }
    switch payload in v {
        case int:    s = fmt.aprintf("\033[93m%i\033[0m", payload)
        case f32:    s = fmt.aprintf("\033[93m%ff\033[0m", payload)
        case bool:   s = fmt.aprintf("\033[93m%v\033[0m", payload)
        case string: s = fmt.aprintf("\033[93m\"%s\"\033[0m", payload)
    }
    return 
}

unary_to_string :: proc(expr: Unary_Fun) -> (s: string) {
    switch expr.op {
        case .U_Minus:      s = fmt.aprintf("(-%s)",       expr_to_string(expr.e1, ""))
        case .Not:          s = fmt.aprintf("(\033[33mnot\033[0m %s)",    expr_to_string(expr.e1, ""))
        // case .Sqrt:         s = fmt.aprintf("\033[33msqrt\033[0m(%s)",    expr_to_string(expr.e1, ""))
        case .Print:        s = fmt.aprintf("\033[33mprint\033[0m(%s)",   expr_to_string(expr.e1, ""))
        case .Assert:       s = fmt.aprintf("\033[33massert\033[0m(%s)",  expr_to_string(expr.e1, ""))
        case .Read_Float:   s = fmt.aprintf("\033[33mreadFloat\033[0m()")
        case .Read_Int:     s = fmt.aprintf("\033[33mreadInt\033[0m()")
    }
    return
}

binary_to_string :: proc(expr: Binary_Fun) -> (s: string) {
    switch expr.op {
        case .Modulus:          s = fmt.aprintf("(%s %% %s)",    expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Divide:           s = fmt.aprintf("(%s / %s)",   expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Times:            s = fmt.aprintf("(%s * %s)",   expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Minus:            s = fmt.aprintf("%s - %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Plus:             s = fmt.aprintf("%s + %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Less:             s = fmt.aprintf("%s < %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Equals:           s = fmt.aprintf("%s = %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Less_Equals:      s = fmt.aprintf("%s <= %s",    expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Greater:          s = fmt.aprintf("%s > %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Greater_Equals:   s = fmt.aprintf("%s >= %s",    expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Xor:              s = fmt.aprintf("(%s xor %s)", expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Or:               s = fmt.aprintf("(%s or %s)",  expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .And:              s = fmt.aprintf("%s and %s",   expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
    }
    return
}

fields_to_string :: proc(fields: map[string]^Expr) -> (s: string) {
    for k,v in fields {
        s = fmt.aprintf("%s; \033[92m%v\033[0m = %v", s, k, expr_to_string(v, ""))
    }
    if len(fields) == 0 { return "" }
    return s[2:]
}

// match_patterns_to_string :: proc(patterns: map[Match_Pattern]^Expr) -> (s: string) {
//     for k,v in patterns {
//         s = fmt.aprintf("%s; %s {{ %s }} = %v", s, k.label, k.var, expr_to_string(v, ""))
//     }
//     if len(patterns) == 0 { return "" }
//     return s[2:]
// }

fun_app_params_to_string :: proc(params: Exprs) -> (s: string) {
    for p in params {
        s = fmt.aprintf("%s,  %s", s, expr_to_string(p, ""))
    }
    if len(params) == 0 { return "" }
    return s[3:]
}

fun_decl_params_to_string :: proc(params: map[string]^Pretype) -> (s: string) {
    for k,v in params {
        s = fmt.aprintf("%s, \033[93m%s\033[0m : %s", s, k, pretype_to_string(v))
    }
    if len(params) == 0 { return "" }
    return s[2:]
}

expr_to_string :: proc(expr: ^Expr, indent: string, nl: bool = true) -> (s: string) {
    if expr == nil { return }

    s0 := indent

    switch e in expr.variance {
        case Sequence:
            s0 = ""
            s = fmt.aprintf("%s;\n%s", expr_to_string(e.e1, indent, nl), expr_to_string(e.e2, indent, nl))
            if !nl {
                s = fmt.aprintf("%s; %s", expr_to_string(e.e1, indent, nl), expr_to_string(e.e2, indent, nl))
            }
        case Type_Ascription:
            s = fmt.aprintf("%s : %s", expr_to_string(e.e1, ""), pretype_to_string(e.pt))
        case Fun_Decl:
            s = fmt.aprintf("\033[33mfun\033[0m (%s) -> %s", fun_decl_params_to_string(e.params), expr_to_string(e.e1, ""))
        case Fun_App:
            s = fmt.aprintf("\033[95m%s\033[0m(%s)", e.fun, fun_app_params_to_string(e.params))
        // case Match_Case:
        //     s = fmt.aprintf("\033[33mmatch\033[0m %s \033[33mwith\033[0m {{ %s }}", expr_to_string(e.e1, ""), match_patterns_to_string(e.patterns))
        // case Union_Constructor:
        //     s = fmt.aprintf("%s {{ %s }}", e.label, expr_to_string(e.e1, ""))
        case Struct:
            s0 = ""
            s = fmt.aprintf("\033[33mstruct\033[0m {{ %s }}", fields_to_string(e.fields))
        case While:
            s = fmt.aprintf("\033[33mwhile\033[0m %s \033[33mdo\033[0m %s", expr_to_string(e.e1, ""), expr_to_string(e.e2, ""))
        case Type_Decl:
            s = fmt.aprintf("\033[33mtype\033[0m \033[91m%s\033[0m = %s;\n%s", e.x, pretype_to_string(e.pt), expr_to_string(e.e1, indent))
        case Let:
            if e.is_mut {
                s = fmt.aprintf("\033[33mlet mutable\033[0m %s : %s = %s;\n%s", e.x, pretype_to_string(e.pt), expr_to_string(e.e1, ""), expr_to_string(e.e2, indent))
            } else {
                s = fmt.aprintf("\033[33mlet\033[0m %s : %s = %s;\n%s", e.x, pretype_to_string(e.pt), expr_to_string(e.e1, ""), expr_to_string(e.e2, indent))
            }
        case If_Else:
            s = fmt.aprintf("(\033[33mif\033[0m %s \033[33mthen\033[0m {{ %s }} \033[33melse\033[0m {{ %s }})", expr_to_string(e.e1, indent), expr_to_string(e.e2, indent), expr_to_string(e.e3, indent))
        case Assignment:
            s = fmt.aprintf("(%s <- %s)", expr_to_string(e.e1, ""), expr_to_string(e.e2, ""))
        case Unary_Fun:

            s = fmt.aprintf("%s", unary_to_string(e))
        case Binary_Fun:
            s = fmt.aprintf("%s", binary_to_string(e))
        case Variable:
            s = fmt.aprintf("\033[93m%s\033[0m", e.x)
        case Field_Access:
            s = fmt.aprintf("(%s.\033[92m%s\033[0m)", expr_to_string(e.e1, ""), e.field)
        case Value:
            s = fmt.aprintf("%s", value_to_string(e.v))
        case Parens:
            s = fmt.aprintf("(%s)", expr_to_string(e.e1, "", false))
        case Scope:
            s = fmt.aprintf("{{ %s }}", expr_to_string(e.e1, "", false))
    }
    s0 = fmt.aprintf("%s%s", s0, s)
    // s0 = fmt.aprintf("[[ %s | %s ]]", s0, t_to_string(expr.type))
    return s0
}

t_to_string :: proc(t: T) -> (s: string) {
    switch t.kind {
        case .Int: s = "int"
        case .Bool: s = "bool"
        case .Unit: s = "unit"
        case .String: s = "string"
        case .Float: s = "float"
        case .Type_Var: s = "type_var"
        case .Struct: s = "struct"
        case .Union: s = "union"
        case .Fun_Sign: s = "fun_sign"
    }
    return
}

types_to_string :: proc(params: Pretypes) -> (s: string) {
    for p in params {
        s = fmt.aprintf("%s, %s", s, pretype_to_string(p))
    }
    if len(params) == 0 { return "" }
    return s[2:]
}

labels_to_string :: proc(labels: map[string]^Pretype) -> (s: string) {
    for k,v in labels {
        s = fmt.aprintf("%s; \033[93m%v\033[0m: %v", s, k, pretype_to_string(v))
    }
    if len(labels) == 0 { return "" }
    return s[2:]
}

pretype_fields_to_string :: proc(labels: map[string]^Field_Value) -> (s: string) {
    for k,v in labels {
        if v.is_mut {
            s = fmt.aprintf("%s; \033[92m%v\033[0m : %v", s, k, pretype_to_string(v.pt))
        } else {
            s = fmt.aprintf("%s; \033[31mimmutable\033[0m \033[92m%v\033[0m : %v", s, k, pretype_to_string(v.pt))
        }
    }
    if len(labels) == 0 { return "" }
    return s[2:]
}

pretype_to_string :: proc(pretype: ^Pretype) -> (s: string) {
    if pretype == nil { return }

    switch pt in pretype {
        case Single:
            s = fmt.aprintf("\033[91m%s\033[0m", pt.t)
        case Fun_Sign:
            s = fmt.aprintf("(%s) -> %s", types_to_string(pt.params), pretype_to_string(pt.res))
        case Struct_Type:
            s = fmt.aprintf("\033[94mstruct\033[0m {{ %s }}", pretype_fields_to_string(pt.fields))
        case Union_Type:
            s = fmt.aprintf("\033[94munion\033[0m {{ %s }}", labels_to_string(pt.labels))
    }
    return
}
