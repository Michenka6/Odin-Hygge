package ast

import "core:fmt"

instruction_to_string :: proc(instruction: ^Instruction) -> (s: string) {
    switch i in instruction^ {
        case Load_Address:
	    s = fmt.aprintf("la %s, %s", i.target_register, i.address)
        case Load_Word:
	    s = fmt.aprintf("lw %s, %s", i.target_register, i.word)
        case Load_Immediate_Int:
	    s = fmt.aprintf("li %s, %i", i.target_register, i.value)
        case Load_Immediate_Float:
	    s = fmt.aprintf("lw t1, %s", i.value)
	    s = fmt.aprintf("%s\nfmv.w.x %s, t1", s, i.target_register)
	case Set_If_Zero:
	    s = fmt.aprintf("seqz %s, %s", i.target_register, i.source_register)
	case Jump_If_Zero:
	    s = fmt.aprintf("beqz %s, %s", i.source_register, i.target_register)
        case Sub_Int:
	    s = fmt.aprintf("sub %s, %s, %s", i.target_register, i.lhs, i.rhs)
	case Print_Int:
	    s = fmt.aprintf("mv a0, %s\nli a7, 1\necall", i.source_register)
	case Print_Float:
	    s = fmt.aprintf("fmv.s fa0, %s\nli a7, 2\necall", i.source_register)
	case Print_String:
	    s = fmt.aprintf("mv a0, %s\nli a7, 4\necall", i.source_register)
	case Read_Int:
	    s = fmt.aprintf("li a7, 5\necall\nmv %s a0", i.target_register)
	case Read_Float:
	    s = fmt.aprintf("li a7, 6\necall\nfmv.s %s fa0", i.target_register)
	case And:
	    s = fmt.aprintf("and %s, %s, %s", i.target_register, i.lhs, i.rhs)
	case Exit:
	    s = fmt.aprintf("li a7, 10\necall")
    }
    return
}

instructions_to_string :: proc(instructions: Instructions) -> (s: string) {
    for inst in instructions {
	s = fmt.aprintf("%s\n%s", s, instruction_to_string(inst))
    }
    return
}

command_to_string :: proc(command: ^Command) -> (s: string) {
    // fmt.println(command.expr)
    return instructions_to_string(command.instructions)
}

memory_to_string :: proc(memory: ^Memory) -> (s: string) {
    for k,v in memory.data {
	switch v.type {
	    case .String:
		s = fmt.aprintf("%s\n%s:\n    .string \"%s\"", s, k, v.value)
	    case .Float:
		s = fmt.aprintf("%s\n%s:\n    .word %s", s, k, v.value)
	    case .Int:
		s = fmt.aprintf("%s\n%s:\n    .word %s", s, k, v.value)
	}
    }
    return
}

program_to_string :: proc(program: ^Program) -> (s: string) {
    command: ^Command
    instructions := instructions_make()
    exit := instruction_make()
    exit^ = Exit { 0 }
    append_elem(&instructions, exit)
    command = command_make(nil, instructions)
    append_elem(&program.commands, command)

    s = fmt.aprintf(".data:\n%s", memory_to_string(program.memory))
    s = fmt.aprintf("%s\n.text:", s)
    for command in program.commands {
	s = fmt.aprintf("%s\n%s", s, command_to_string(command))

    }
    return
}
