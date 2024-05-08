package ast

import "core:fmt"
import "core:crypto/hash"

program_make :: proc() -> (program: ^Program) {
    program = new(Program)
    program.memory = memory_make()
    program.commands = make(Commands)
    program.labels   = make(map[string]^Command)


    return
}

memory_make :: proc() -> (memory: ^Memory) {
    memory      = new(Memory)
    memory.data = make(map[string]Memory_Value)
    return
}

instruction_make :: proc() -> (instruction: ^Instruction) {
    instruction = new(Instruction)
    return
}

instructions_make :: proc() -> Instructions {
    instructions := make([dynamic]^Instruction)
    return instructions
}

command_make :: proc(expr: ^Expr, instructions: Instructions) -> (command: ^Command) {
    command = new(Command)
    command^ = Command { expr, instructions }
    return
}

expr_to_ir_command :: proc(expr: ^Expr, program: ^Program, target_register: Register = "") -> (ok: bool) {
    switch e in expr.variance {
        case Sequence:
	    expr_to_ir_command(e.e1, program, target_register) or_return
	    expr_to_ir_command(e.e2, program, target_register) or_return
        case Type_Ascription:
        case Fun_Decl:
        case Fun_App:
        // case Match_Case:
        // case Union_Constructor:
        case Struct:
        case While:
        case Type_Decl:
        case Let:
        case If_Else:
        case Assignment:
        case Unary_Fun:
	    unary_to_ir_command(expr, program, target_register) or_return
        case Binary_Fun:
	    binary_to_ir_command(expr, program, target_register) or_return
        case Variable:
	    command: ^Command
	    instructions := instructions_make()
	    li := instruction_make()
	    li^ = Load_Word { target_register, e.x }
	    if expr.type.kind == .String {
		li^ = Load_Address { target_register, e.x }
	    }
	    append(&instructions, li)
	    command = command_make(expr, instructions)
	    append_elem(&program.commands, command)
        case Field_Access:
        case Value:
	    return value_to_ir_command(expr, program, target_register)
        case Parens:
	    expr_to_ir_command(e.e1, program, target_register) or_return
        case Scope:
	    expr_to_ir_command(e.e1, program, target_register) or_return
    }
    return true
}

hash_string :: proc(s: string) -> (res: string) {
    for x in s {
	a := 'A' <= x && x <= 'Z'
	b := 'a' <= x && x <= 'z'
	c := '0' <= x && x <= '9'
	if a || b || c {
	    res = fmt.aprintf("%s%v", res, x)
	}
    }
    return
}

value_to_ir_command :: proc(expr: ^Expr, program: ^Program, target_register: Register = "") -> (ok: bool) {
    value := expr.variance.(Value)
    command: ^Command
    instructions := instructions_make()
    switch value.type {
       case .Int:
	i := fmt.aprintf("%v", value.v.(int))
	s := fmt.aprintf("i_%s", hash_string(i))
	program.memory.data[s] = Memory_Value { i, .Int }

	li := instruction_make()
	li^ = Load_Word { target_register, s }

	append(&instructions, li)
	command = command_make(expr, instructions)
       case .Bool:
	li := instruction_make()
	if value.v.(bool) {
	    li^ = Load_Immediate_Int { target_register, 1 }
	} else {
	    li^ = Load_Immediate_Int { target_register, 0 }
	}

	append(&instructions, li)
	command = command_make(expr, instructions)
       case .String:
	s := value.v.(string)
	s = hash_string(s)
	program.memory.data[s] = Memory_Value { value.v.(string), .String }

	li := instruction_make()
	li^ = Load_Address { target_register, s }

	append(&instructions, li)
	command = command_make(expr, instructions)
       case .Float:
	i := fmt.aprintf("%v", transmute(u32)value.v.(f32))
	s := fmt.aprintf("i_%s", hash_string(i))
	program.memory.data[s] = Memory_Value { i, .Float}

	li := instruction_make()
	li^ = Load_Immediate_Float { target_register, s }

	append(&instructions, li)
	command = command_make(expr, instructions)
       case .Unit:
	fmt.eprintln("Cannot convert Unit to IR")
    }

    append_elem(&program.commands, command)
    return true
}

binary_to_ir_command :: proc(expr: ^Expr, program: ^Program, target_register: Register = "") -> (ok: bool) {
    e := expr.variance.(Binary_Fun)
    command: ^Command
    instructions := instructions_make()
    inst := instruction_make()
    switch e.op {
        case .Xor:
        case .Or:
        case .And:
	    expr_to_ir_command(e.e1, program, "t1") or_return
	    expr_to_ir_command(e.e2, program, "t2") or_return
	    inst^ = And { target_register, "t1", "t2" }
        case .Less:
        case .Less_Equals:
        case .Greater:
        case .Greater_Equals:
        case .Equals:
        case .Modulus:
        case .Divide:
        case .Times:
        case .Plus:
        case .Minus:
    }

    append_elem(&instructions, inst)
    command = command_make(expr, instructions)
    append_elem(&program.commands, command)

    return true
}
unary_to_ir_command :: proc(expr: ^Expr, program: ^Program, target_register: Register = "") -> (ok: bool) {
    e := expr.variance.(Unary_Fun)
    command: ^Command
    instructions := instructions_make()

    switch e.op {
	case .U_Minus:
	    expr_to_ir_command(e.e1, program, target_register) or_return
	    sub := instruction_make()
	    sub^ = Sub_Int { target_register, "zero", target_register }
	    append_elem(&instructions, sub)
	    command = command_make(expr, instructions)
	case .Not:
	    expr_to_ir_command(e.e1, program, target_register) or_return
	    seqz := instruction_make()
	    seqz^ = Set_If_Zero { target_register, target_register }
	    append_elem(&instructions, seqz)
	    command = command_make(expr, instructions)
	case .Print:
	    expr_to_ir_command(e.e1, program, target_register) or_return
	    print := instruction_make()
	    switch e.e1.type.kind {
                case .Int:
		    print^ = Print_Int { target_register }
                case .Bool:
		    print^ = Print_Int { target_register }
                case .Unit:
                case .String:
		    print^ = Print_String { target_register }
                case .Float:
		    print^ = Print_Float { target_register }
                case .Type_Var:
                case .Struct:
                case .Union:
                case .Fun_Sign:
	    }
	    append_elem(&instructions, print)
	    command = command_make(expr, instructions)
	case .Assert:
	    expr_to_ir_command(e.e1, program, target_register) or_return

	    jump := instruction_make()
	    jump^ = Jump_If_Zero { target_register, "assert_false" }

	    append_elem(&instructions, jump)
	    command = command_make(expr, instructions)
	case .Read_Int:
	    read_int := instruction_make()
	    read_int^ = Read_Int { target_register }

	    append_elem(&instructions, read_int)
	    command = command_make(expr, instructions)
	case .Read_Float:
	    read_float := instruction_make()
	    read_float^ = Read_Float { target_register }

	    append_elem(&instructions, read_float)
	    command = command_make(expr, instructions)
    }

    append_elem(&program.commands, command)
    return true
}
