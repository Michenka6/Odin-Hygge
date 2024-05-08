package typechecker

import AST "../ast"
import "core:fmt"

Type_Env :: AST.Type_Env
T        :: AST.T
Ts       :: AST.Ts
T_Kind   :: AST.T_Kind

type_env_make :: proc() -> (env: ^Type_Env) {
    env = new(Type_Env)
    env.vars = make(map[string]^T)
    env.type_vars = make(map[string]^T)
    env.immutables = make([dynamic]string)
    return
}

t_make :: proc(x: string = "", kind: T_Kind, mapping: map[string]^T = nil, params: Ts = nil, res: ^T = nil) -> (t: ^T) {
    t  = new(T)
    t^ = T { x, kind, mapping, params, res }
    return
}

type_checking_judgement :: proc(env: ^Type_Env, expr: ^AST.Expr) -> (ok: bool) {
    // fmt.println(expr.variance)
    switch e in expr.variance {
        case AST.Sequence:
            type_checking_judgement(env, e.e1) or_return
            type_checking_judgement(env, e.e2) or_return
            expr.type = e.e2.type
        case AST.Type_Ascription:
            type_checking_judgement(env, e.e1) or_return
            t := type_resolution_judgement(env, e.pt) or_return
            if t.kind != e.e1.type.kind { return false }
            expr.type = t
        case AST.Fun_Decl:
            type_checking_judgement(env, e.e1) or_return
            res := e.e1.type
            mapping := make(map[string]^T)
            for k,v in e.params {
                tt := type_resolution_judgement(env, v) or_return
                env.vars[k] = tt
                mapping[k] = tt
            }
            t := t_make(kind = .Fun_Sign, mapping = mapping, res = res)
            expr.type = t
        case AST.Fun_App:
            t := env.vars[e.fun] or_return
            if len(t.params) != len(e.params) { return false }

            for param, i in e.params {
                type_checking_judgement(env, param) or_return
                if t.params[i].kind != param.type.kind { return false }
            }
            expr.type = t.res
        // case AST.Match_Case:
        //     fmt.eprintln("NOT IMPLEMENTED")
        // case AST.Union_Constructor:
        //     fmt.eprintln("NOT IMPLEMENTED")
        case AST.Struct:
            fmt.eprintln("NOT IMPLEMENTED")
        case AST.While:
            type_checking_judgement(env, e.e1) or_return
            type_checking_judgement(env, e.e2) or_return
            if e.e1.type.kind != .Bool { return false }
            expr.type = t_make(kind = .Unit)
        case AST.Type_Decl:
            t := type_resolution_judgement(env, e.pt) or_return
            env.type_vars[e.x] = t
            type_checking_judgement(env, e.e1) or_return
            expr.type = e.e1.type
        case AST.Let:
            t := type_resolution_judgement(env, e.pt) or_return
            env.vars[e.x] = t

            type_checking_judgement(env, e.e1) or_return
            type_checking_judgement(env, e.e2) or_return

            expr.type = e.e2.type
        case AST.If_Else:
            type_checking_judgement(env, e.e1) or_return
            if e.e1.type.kind != .Bool { return false }

            type_checking_judgement(env, e.e2) or_return
            type_checking_judgement(env, e.e3) or_return
            if e.e2.type.kind != e.e3.type.kind { return false }
            expr.type = e.e2.type
        case AST.Assignment:
            type_checking_judgement(env, e.e1) or_return
            type_checking_judgement(env, e.e2) or_return
            if e.e1.type.kind != e.e2.type.kind { return false }
            expr.type = e.e1.type
        case AST.Unary_Fun:
            type_checking_judgement_unary(env, expr)
        case AST.Binary_Fun:
            type_checking_judgement_binary(env, expr)
        case AST.Variable:
            expr.type = env.vars[e.x] or_return
        case AST.Field_Access:
            fmt.eprintln("NOT IMPLEMENTED")
        case AST.Value:
            switch e.type {
                case .Int:
                    expr.type = t_make(kind = .Int)
                case .Bool:
                    expr.type = t_make(kind = .Bool)
                case .String:
                    expr.type = t_make(kind = .String)
                case .Float:
                    expr.type = t_make(kind = .Float)
                case .Unit:
                    expr.type = t_make(kind = .Unit)
            }
        case AST.Parens:
            type_checking_judgement(env, e.e1) or_return
            expr.type = e.e1.type
        case AST.Scope:
            type_checking_judgement(env, e.e1) or_return
            expr.type = e.e1.type
    }
    return true
}

type_checking_judgement_unary :: proc(env: ^Type_Env, expr: ^AST.Expr) -> (ok: bool) {
    e := expr.variance.(AST.Unary_Fun)
    switch e.op {
        case .U_Minus:
        // case .Sqrt:
            type_checking_judgement(env, e.e1) or_return
            if e.e1.type.kind != .Int && e.e1.type.kind != .Float { return false }
            expr.type = e.e1.type
        case .Print:
            type_checking_judgement(env, e.e1) or_return
            kind := e.e1.type.kind
            expr.type = t_make(kind = .Unit)
            printable := [?]T_Kind{ .Int, .Float, .String, .Bool }
            for k in printable {
                if k == kind { return true }
            }
            return false
        case .Not:
            type_checking_judgement(env, e.e1) or_return
            if e.e1.type.kind != .Bool { return false }
            expr.type = e.e1.type
        case .Assert:
            type_checking_judgement(env, e.e1) or_return
            if e.e1.type.kind != .Bool { return false }
            expr.type = t_make(kind = .Unit)
        case .Read_Int: fallthrough
        case .Read_Float:
            expr.type = t_make(kind = .Unit)
    }
    return true
}

type_checking_judgement_binary :: proc(env: ^Type_Env, expr: ^AST.Expr) -> (ok: bool) {
    e := expr.variance.(AST.Binary_Fun)
    switch e.op {
        case .Xor:      fallthrough
        case .Or:       fallthrough
        case .And:
            type_checking_judgement(env, e.e1) or_return
            type_checking_judgement(env, e.e2) or_return

            if e.e1.type.kind != e.e2.type.kind { return false }
            if e.e1.type.kind != .Bool          { return false }

            expr.type = e.e1.type
        case .Less:             fallthrough
        case .Less_Equals:      fallthrough
        case .Greater:          fallthrough
        case .Greater_Equals:   fallthrough
        case .Equals:
            type_checking_judgement(env, e.e1) or_return
            type_checking_judgement(env, e.e2) or_return

            if e.e1.type.kind != e.e2.type.kind { return false }
            if e.e1.type.kind != .Int {
                if e.e1.type.kind != .Float     { return false }
            }

            expr.type = t_make(kind = .Bool)
        case .Modulus:  fallthrough
        case .Divide:   fallthrough
        case .Times:    fallthrough
        case .Plus:     fallthrough
        case .Minus:
            type_checking_judgement(env, e.e1) or_return
            type_checking_judgement(env, e.e2) or_return

            if e.e1.type.kind != e.e2.type.kind { return false }
            if e.e1.type.kind != .Int {
                if e.e1.type.kind != .Float     { return false }
            }

            expr.type = e.e1.type
    }
    return true
}

type_resolution_judgement :: proc(env: ^Type_Env, pt: ^AST.Pretype) -> (t: ^T, ok: bool) {
    switch p in pt {
        case AST.Fun_Sign:
            params := make(Ts)
            for param in p.params {
                t1, t1_ok := type_resolution_judgement(env, param)
                if !t1_ok { return nil, false }
                append_elem(&params, t1)
            }
            res, res_ok := type_resolution_judgement(env, p.res)
            t  = t_make(kind = .Fun_Sign, res = res, params = params)
            ok = true
        case AST.Struct_Type:
            mapping := make(map[string]^T)
            for k,v in p.fields {
                t1, t1_ok := type_resolution_judgement(env, v.pt)
                if !t1_ok { return nil, false }
                mapping[k] = t1
            }
            t  = t_make(kind = .Struct, mapping = mapping)
            ok = true
        case AST.Union_Type:
            fmt.eprintln("NOT IMPLEMENTED")
        case AST.Single:
            switch p.t {
                case "int":     
                    t  = t_make(kind = .Int)
                    ok = true
                case "float":   
                    t  = t_make(kind = .Float)
                    ok = true
                case "unit":    
                    t  = t_make(kind = .Unit)
                    ok = true
                case "string":  
                    t  = t_make(kind = .String)
                    ok = true
                case "bool":    
                    t  = t_make(kind = .Bool)
                    ok = true
                case:
                    t, ok = env.type_vars[p.t]
        }
    }
    return
}

// type_checking_judgement :: proc(env: ^Type_Env, expr: ^AST.Expr) -> (t: ^T, ok: bool) {
//     if expr == nil { return }
//     switch e in expr.variance {
//         case AST.Sequence:
//             t1, t1_ok := type_checking_judgement(env, e.e1)
//             if !t1_ok || t1.kind != .Unit { return nil, false }
//             t, ok  = type_checking_judgement(env, e.e2)
//         case AST.Type_Ascription:
//             t, ok = type_resolution_judgement(env, e.pt)
//             t1, t1_resolved := type_checking_judgement(env, e.e1)
//             ok &= t.kind == t1.kind && t1_resolved
//         case AST.Fun_Decl:
//             params := make(Ts)
//             for k,v in e.params {
//                 t1, t1_ok := type_resolution_judgement(env, v)
//                 if !t1_ok { return nil, false }
//                 env.vars[k] = t1
//                 append_elem(&params, t1)
//             }
//
//             res, res_ok := type_checking_judgement(env, e.e1)
//             if !res_ok { return nil, false }
//             t = t_make(kind = .Fun_Sign, params = params, res = res)
//             ok = true
//         case AST.Fun_App:
//             params := make([dynamic]^T)
//             for param in e.params {
//                 t2, t2_ok := type_checking_judgement(env, param)
//                 if !t2_ok { return nil, false }
//                 append_elem(&params, t2)
//             }
//
//             if len(params) != len(t.params) { return nil, false }
//             for i in 0..<len(params) {
//                 if params[i].kind != t.params[i].kind { return nil, false }
//             }
//             t  = t_make(kind = .Unit)
//             ok = true
//         case AST.Match_Case:
//         case AST.Union_Constructor:
//         case AST.Struct:
//             mapping := make(map[string]^T)
//             for k,v in e.fields {
//                 t1, t1_ok := type_checking_judgement(env, v)
//                 if !t1_ok { return nil, false }
//                 mapping[k] = t1
//             }
//             t  = t_make(kind = .Struct, mapping = mapping)
//             ok = true
//         case AST.While:
//             t1, t1_ok := type_checking_judgement(env, e.e1)
//             t2, t2_ok := type_checking_judgement(env, e.e2)
//             if t1.kind != .Bool || t2.kind != .Unit || !t1_ok || !t2_ok { return nil, false }
//             t  = t_make(kind = .Unit)
//             ok = true
//         case AST.Type_Decl:
//             not_allowed :: proc(x:string) -> bool { return x == "int" || x == "float" || x == "string" || x == "unit" || x == "bool" }
//             t1, t1_ok := type_resolution_judgement(env, e.pt)
//             if !t1_ok || not_allowed(e.x) || e.x in env.type_vars { return nil, false }
//             env.type_vars[e.x] = t1
//             t, ok = type_checking_judgement(env, e.e1)
//         case AST.Let:
//             t1, t1_ok := type_resolution_judgement(env, e.pt)
//             t2, t2_ok := type_checking_judgement(env, e.e1)
//             // fmt.println(t1.mapping)
//             // fmt.println(t2.mapping)
//             if !t1_ok || !t2_ok || !pretype_eq(t1, t2) { return nil, false }
//             env.vars[e.x] = t2
//             if !e.is_mut { append_elem(&env.immutables, e.x) }
//             t, ok = type_checking_judgement(env, e.e2)
//         case AST.If_Else:
//             t1, ok1 := type_checking_judgement(env, e.e1)
//             if !ok1 || t1.kind != .Bool { return nil, false }
//             t2, ok2 := type_checking_judgement(env, e.e2)
//             t3, ok3 := type_checking_judgement(env, e.e3)
//             if !ok2 || !ok3 || t2.kind != t3.kind { return nil, false }
//             t, ok = t2, true
//         case AST.Assignment:
//             t1, ok1 := type_checking_judgement(env, e.e1)
//             t2, ok2 := type_checking_judgement(env, e.e2)
//             if !ok1 || !ok2 || t1.kind != t2.kind { return nil, false }
//             // @TODO does not check for immutables
//             t  = t_make(kind = .Unit)
//             ok = true
//         case AST.Unary_Fun:
//             t, ok = type_checking_judgement_unary(env, &e)
//         case AST.Binary_Fun:
//             t, ok = type_checking_judgement_binary(env, &e)
//         case AST.Variable:
//             t, ok = env.vars[e.x]
//         case AST.Field_Access:
//         case AST.Parens:
//             t, ok = type_checking_judgement(env, e.e1)
//         case AST.Scope:
//             t, ok = type_checking_judgement(env, e.e1)
//         case AST.Value:
//             ok = true
//             switch e.type {
//                 case .Int:        t = t_make(kind = .Int)
//                 case .Bool:        t = t_make(kind = .Bool)
//                 case .String:    t = t_make(kind = .String)
//                 case .Float:    t = t_make(kind = .Float)
//                 case .Unit:        t = t_make(kind = .Unit)
//             }
//     }
//     return
// }
//
// pretype_eq :: proc(a: ^T, b: ^T) -> bool {
//     if a == nil || b == nil || a.kind != b.kind { return false }
//
//     #partial switch a.kind {
//         case .Type_Var:
//             return a.x == b.x
//         case .Struct:
//             if len(a.mapping) != len(b.mapping) { return false }
//             for k,v1 in a.mapping {
//                 v2, ok := b.mapping[k]
//                 if !ok { return false }
//                 if !pretype_eq(v1, v2) { return false }
//             }
//         case .Union:
//         case .Fun_Sign:
//     }
//     return true
// }
//
// type_checking_judgement_unary :: proc(env: ^Type_Env, expr: ^AST.Unary_Fun) -> (t: ^T, ok: bool) {
//     if expr == nil { return }
//     switch expr.op {
//         case .U_Minus:
//             t, ok = type_checking_judgement(env, expr.e1)
//             ok   &= (t.kind == .Int || t.kind == .Float)
//         case .Sqrt:
//             t, ok = type_checking_judgement(env, expr.e1)
//             ok   &= (t.kind == .Int || t.kind == .Float)
//         case .Not:
//             t, ok = type_checking_judgement(env, expr.e1)
//             ok   &= t.kind ==.Bool
//         case .Print:        fallthrough
//         case .Println:
//             t, ok = type_checking_judgement(env, expr.e1)
//             ok   &= (t.kind == .Int || t.kind == .Bool || t.kind == .Float || t.kind == .String)
//             t     = t_make(kind = .Unit)
//         case .Assert:
//             t, ok = type_checking_judgement(env, expr.e1)
//             ok   &= t.kind == .Bool
//         case .Read_Int:     fallthrough
//         case .Read_Float:
//             t  = t_make(kind = .Unit)
//             ok = true
//     }
//     return
// }
//
// type_checking_judgement_binary :: proc(env: ^Type_Env, expr: ^AST.Binary_Fun) -> (t: ^T, ok: bool) {
//     if expr == nil { return }
//     switch expr.op {
//         case .Xor:          fallthrough
//         case .Or:           fallthrough
//         case .And:
//             t1, t1_ok := type_checking_judgement(env, expr.e1)
//             t2, t2_ok := type_checking_judgement(env, expr.e2)
//             t  = t_make(kind = .Bool)
//             ok = t1.kind == .Bool && t2.kind == .Bool
//         case .Equals:           fallthrough
//         case .Greater:          fallthrough
//         case .Greater_Equals:   fallthrough
//         case .Less:             fallthrough
//         case .Less_Equals:
//             t1, t1_ok := type_checking_judgement(env, expr.e1)
//             t2, t2_ok := type_checking_judgement(env, expr.e2)
//             t  = t_make(kind = .Bool)
//             ok = t1.kind == t2.kind && (t1.kind == .Int || t1.kind == .Float)
//         case .Modulus:      fallthrough
//         case .Divide:       fallthrough
//         case .Times:        fallthrough
//         case .Plus:         fallthrough
//         case .Minus:        fallthrough
//         case .Max:          fallthrough
//         case .Min:
//             t1, t1_ok := type_checking_judgement(env, expr.e1)
//             t2, t2_ok := type_checking_judgement(env, expr.e2)
//             t  = t_make(kind = t1.kind)
//             ok = t1.kind == t2.kind && (t1.kind == .Int || t1.kind == .Float)
//     }
//     return
// }
