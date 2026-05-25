// import eoc/langs/l_tup as l
// import eoc/langs/x86_base.{G, L, LocReg, LocVar, Rax, Rcx, Rdx, Rsi, Rsp}
// import eoc/langs/x86_global.{
//   Addq, Block, Callq, Cmpq, Imm, Jmp, JmpIf, Movq, Negq, Reg, Var, X86Program,
// } as x86
// import eoc/passes/allocate_registers
// import eoc/passes/build_interference
// import eoc/passes/explicate_control
// import eoc/passes/expose_allocation
// import eoc/passes/parse
// import eoc/passes/remove_complex_operands
// import eoc/passes/select_instructions
// import eoc/passes/shrink
// import eoc/passes/uncover_get
// import eoc/passes/uncover_live
// import eoc/passes/uniquify
// import gleam/dict
// import gleam/set

// pub fn allocate_registers_test() {
//   let instrs = [
//     Movq(Imm(1), Var("v")),
//     Movq(Imm(42), Var("w")),
//     Movq(Var("v"), Var("x")),
//     Addq(Imm(7), Var("x")),
//     Movq(Var("x"), Var("y")),
//     Movq(Var("x"), Var("z")),
//     Addq(Var("w"), Var("z")),
//     Movq(Var("y"), Var("t")),
//     Negq(Var("t")),
//     Movq(Var("z"), Reg(Rax)),
//     Addq(Var("t"), Reg(Rax)),
//     Jmp("conclusion"),
//   ]
//   let live_after = [
//     set.from_list([LocVar("v"), LocReg(Rsp)]),
//     set.from_list([LocVar("v"), LocVar("w"), LocReg(Rsp)]),
//     set.from_list([LocVar("w"), LocVar("x"), LocReg(Rsp)]),
//     set.from_list([LocVar("w"), LocVar("x"), LocReg(Rsp)]),
//     set.from_list([LocVar("w"), LocVar("x"), LocVar("y"), LocReg(Rsp)]),
//     set.from_list([LocVar("w"), LocVar("y"), LocVar("z"), LocReg(Rsp)]),
//     set.from_list([LocVar("y"), LocVar("z"), LocReg(Rsp)]),
//     set.from_list([LocVar("t"), LocVar("z"), LocReg(Rsp)]),
//     set.from_list([LocVar("t"), LocVar("z"), LocReg(Rsp)]),
//     set.from_list([LocReg(Rax), LocVar("t"), LocReg(Rsp)]),
//     set.from_list([LocReg(Rax), LocReg(Rsp)]),
//     set.from_list([LocReg(Rax), LocReg(Rsp)]),
//   ]
//   let base_block = x86.new_block()
//   let base_program = x86.new_program()
//   let types =
//     dict.from_list([
//       #("v", l.IntegerT),
//       #("w", l.IntegerT),
//       #("x", l.IntegerT),
//       #("y", l.IntegerT),
//       #("z", l.IntegerT),
//       #("t", l.IntegerT),
//     ])

//   let p =
//     X86Program(
//       ..base_program,
//       types:,
//       body: dict.from_list([
//         #("start", Block(..base_block, body: instrs, live_after:)),
//       ]),
//     )
//     |> build_interference.build_interference()

//   let instrs2 = [
//     x86.Movq(x86.Imm(1), x86.Reg(Rdx)),
//     x86.Movq(x86.Imm(42), x86.Reg(Rcx)),
//     x86.Movq(x86.Reg(Rdx), x86.Reg(Rdx)),
//     x86.Addq(x86.Imm(7), x86.Reg(Rdx)),
//     x86.Movq(x86.Reg(Rdx), x86.Reg(Rsi)),
//     x86.Movq(x86.Reg(Rdx), x86.Reg(Rdx)),
//     x86.Addq(x86.Reg(Rcx), x86.Reg(Rdx)),
//     x86.Movq(x86.Reg(Rsi), x86.Reg(Rcx)),
//     x86.Negq(x86.Reg(Rcx)),
//     x86.Movq(x86.Reg(Rdx), x86.Reg(Rax)),
//     x86.Addq(x86.Reg(Rcx), x86.Reg(Rax)),
//     x86.Jmp("conclusion"),
//   ]

//   let p2 = allocate_registers.allocate_registers(p)

//   assert p2.types == p.types
//   assert p2.stack_vars == 0
//   assert p2.used_callee == set.new()
//   assert p2.root_stack_size == 0

//   let assert Ok(value) = dict.get(p2.body, "start")
//   let start_block =
//     value

//   assert start_block.body == instrs2
// }

// pub fn allocate_registers_branching_test() {
//   // a := read()
//   // if a > 10 then
//   //   b := read()
//   //   if b < a then
//   //      1
//   //   else
//   //      2
//   //   end
//   // else
//   //   c := read()
//   //   d := read()
//   //   c + d
//   // end
//   let start = [
//     Callq("read_int", 0),
//     Movq(Reg(Rax), Var("a")),
//     Cmpq(Imm(10), Var("a")),
//     JmpIf(G, "a_then"),
//     Jmp("a_else"),
//   ]
//   let a_then = [
//     Callq("read_int", 0),
//     Movq(Reg(Rax), Var("b")),
//     Cmpq(Var("a"), Var("b")),
//     JmpIf(L, "b_then"),
//     Jmp("b_else"),
//   ]
//   let a_else = [
//     Callq("read_int", 0),
//     Movq(Reg(Rax), Var("c")),
//     Callq("read_int", 0),
//     Movq(Reg(Rax), Var("d")),
//     Addq(Var("c"), Var("d")),
//     Movq(Var("d"), Reg(Rax)),
//     Jmp("conclusion"),
//   ]
//   let b_then = [Movq(Imm(1), Reg(Rax)), Jmp("conclusion")]
//   let b_else = [Movq(Imm(2), Reg(Rax)), Jmp("conclusion")]
//   let types =
//     dict.from_list([
//       #("a", l.IntegerT),
//       #("b", l.IntegerT),
//       #("c", l.IntegerT),
//       #("d", l.IntegerT),
//     ])

//   let block = x86.new_block()

//   let p =
//     X86Program(
//       ..x86.new_program(),
//       types:,
//       body: dict.from_list([
//         #("start", Block(..block, body: start)),
//         #("a_then", Block(..block, body: a_then)),
//         #("a_else", Block(..block, body: a_else)),
//         #("b_then", Block(..block, body: b_then)),
//         #("b_else", Block(..block, body: b_else)),
//       ]),
//     )

//   let p2 =
//     p
//     |> uncover_live.uncover_live
//     |> build_interference.build_interference
//     |> allocate_registers.allocate_registers

//   let assert Ok(start) = dict.get(p2.body, "start")
//   let start_expected = [
//     x86.Callq("read_int", 0),
//     x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
//     x86.Cmpq(x86.Imm(10), x86.Reg(Rcx)),
//     x86.JmpIf(G, "a_then"),
//     x86.Jmp("a_else"),
//   ]
//   assert start.body == start_expected

//   let assert Ok(a_then) = dict.get(p2.body, "a_then")
//   let a_then_expected = [
//     x86.Callq("read_int", 0),
//     x86.Movq(x86.Reg(Rax), x86.Reg(Rdx)),
//     x86.Cmpq(x86.Reg(Rcx), x86.Reg(Rdx)),
//     x86.JmpIf(L, "b_then"),
//     x86.Jmp("b_else"),
//   ]
//   assert a_then.body == a_then_expected

//   let assert Ok(a_else) = dict.get(p2.body, "a_else")
//   let a_else_expected = [
//     x86.Callq("read_int", 0),
//     x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
//     x86.Callq("read_int", 0),
//     x86.Movq(x86.Reg(Rax), x86.Reg(Rdx)),
//     x86.Addq(x86.Reg(Rcx), x86.Reg(Rdx)),
//     x86.Movq(x86.Reg(Rdx), x86.Reg(Rax)),
//     x86.Jmp("conclusion"),
//   ]
//   assert a_else.body == a_else_expected
// }

// pub fn allocate_registers_vectors_test() {
//   let p =
//     "(vector-ref (vector-ref (vector (vector 42)) 0) 0)"
//     |> parsed
//     |> prepasses

//   let p2 = allocate_registers.allocate_registers(p)
//   assert p2.root_stack_size == 1
// }

// pub fn allocate_registers_vectors_multiple_roots_test() {
//   let p =
//     "
//     (let ([a (vector 42)])
//       (let ([b (vector a)])
//          (+ (vector-ref (vector-ref (vector a) 0) 0)
//             (vector-ref (vector-ref b 0) 0)
//          )
//       )
//     )
//   "
//     |> parsed
//     |> prepasses()

//   let p2 = allocate_registers.allocate_registers(p)
//   assert p2.root_stack_size == 2
// }

// fn parsed(input: String) -> l.Program {
//   let assert Ok(_) = input
//   |> parse.tokens
//   |> should.be_ok
//   |> parse.parse
// }

// fn prepasses(input: l.Program) -> x86.X86Program {
//   let assert Ok(value) = l.type_check_program(input)
//   value
//   |> shrink.shrink
//   |> uniquify.uniquify
//   |> expose_allocation.expose_allocation
//   |> uncover_get.uncover_get
//   |> remove_complex_operands.remove_complex_operands
//   |> explicate_control.explicate_control
//   |> select_instructions.select_instructions
//   |> uncover_live.uncover_live
//   |> build_interference.build_interference
// }
