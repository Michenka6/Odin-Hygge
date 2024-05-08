package ast

Program :: struct {
    memory:    ^Memory,
    commands:   Commands,
    labels:     map[string]^Command,
    max_pc:     u64,
    pc:         u64,
}

Memory :: struct {
    data: map[string]Memory_Value,
}

Memory_Value :: struct {
    value: string,
    type:  enum {
        String,
        Float,
        Int,
    }
}

Register :: string

Commands :: [dynamic]^Command
Command :: struct {
    expr:          ^Expr,
    instructions:   Instructions,
}

Instructions :: [dynamic]^Instruction
Instruction :: union {
    Load_Address,
    Load_Word,
    Load_Immediate_Int,
    Load_Immediate_Float,
    Set_If_Zero,
    Jump_If_Zero,
    Sub_Int,
    Print_Int,
    Print_Float,
    Print_String,
    Read_Int,
    Read_Float,
    And,
    Exit,
}

Load_Word :: struct {
    target_register:    Register,
    word:               string,
}

Load_Immediate_Int :: struct {
    target_register:    Register,
    value:              int,
}

Load_Immediate_Float :: struct {
    target_register:    Register,
    value:              string,
}

Load_Address :: struct {
    target_register:    Register,
    address:            Register,
}

Set_If_Zero :: struct {
    target_register:    Register,
    source_register:    Register,
}

Jump_If_Zero :: struct {
    source_register:    Register,
    target_register:    Register,
}

Sub_Int :: struct {
    target_register:    Register,
    lhs:                Register,
    rhs:                Register,
}

Print_Int :: struct {
    source_register:    Register,
}

Print_Float :: struct {
    source_register:    Register,
}

Print_String :: struct {
    source_register:    Register,
}

Read_Int :: struct {
    target_register:    Register,
}

Read_Float :: struct {
    target_register:    Register,
}

And :: struct {
    target_register:    Register,
    lhs:                Register,
    rhs:                Register,
}

Exit :: struct {
    exit_code:          int,
}
