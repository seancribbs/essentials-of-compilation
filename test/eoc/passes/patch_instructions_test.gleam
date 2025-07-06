import eoc/langs/x86_base.{E, Rax, Rbp, Rcx, Rsp}
import eoc/langs/x86_if as x86
import eoc/passes/patch_instructions.{patch_instructions}
import gleam/dict
import gleam/set
import gleeunit/should

pub fn patch_instructions_test() {
  let p1 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -24)),
            x86.Addq(x86.Deref(Rbp, -16), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      24,
      set.new(),
    )

  let p2 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -16), x86.Reg(Rax)),
            x86.Addq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      24,
      set.new(),
    )

  p1 |> patch_instructions() |> should.equal(p2)
}

pub fn patch_instructions_ch3_test() {
  let p1 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(1), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(42), x86.Reg(Rcx)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -8)),
            x86.Addq(x86.Imm(7), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -8)),
            x86.Addq(x86.Reg(Rcx), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -16), x86.Reg(Rcx)),
            x86.Negq(x86.Reg(Rcx)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Addq(x86.Reg(Rcx), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      24,
      set.new(),
    )

  let p2 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(1), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(42), x86.Reg(Rcx)),
            x86.Addq(x86.Imm(7), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -16)),
            x86.Addq(x86.Reg(Rcx), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -16), x86.Reg(Rcx)),
            x86.Negq(x86.Reg(Rcx)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Addq(x86.Reg(Rcx), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      24,
      set.new(),
    )

  p1 |> patch_instructions() |> should.equal(p2)
}

pub fn patch_instructions_cmp_immediate_test() {
  let body = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Cmpq(x86.Reg(Rcx), x86.Imm(5)),
    x86.Set(E, x86_base.Al),
    x86.Movzbq(x86_base.Al, x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]
  let p =
    x86.X86Program(dict.from_list([#("start", x86.Block(body))]), 0, set.new())
    |> patch_instructions

  let body_expected = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Movq(x86.Imm(5), x86.Reg(Rax)),
    x86.Cmpq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Set(E, x86_base.Al),
    x86.Movzbq(x86_base.Al, x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]

  let assert Ok(x86.Block(body_actual)) = dict.get(p.body, "start")
  body_actual |> should.equal(body_expected)
}

pub fn patch_instructions_movzbq_stack_test() {
  let body = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Movq(x86.Imm(5), x86.Reg(Rax)),
    x86.Cmpq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Set(E, x86_base.Al),
    // This next instruction is invalid
    x86.Movzbq(x86_base.Al, x86.Deref(Rsp, -8)),
    x86.Movq(x86.Imm(1), x86.Reg(Rax)),
    x86.Xorq(x86.Deref(Rsp, -8), x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]

  let p =
    x86.X86Program(dict.from_list([#("start", x86.Block(body))]), 0, set.new())
    |> patch_instructions

  let body_expected = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Movq(x86.Imm(5), x86.Reg(Rax)),
    x86.Cmpq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Set(E, x86_base.Al),
    // The next two instructions replace the one above
    x86.Movzbq(x86_base.Al, x86.Reg(Rax)),
    x86.Movq(x86.Reg(Rax), x86.Deref(Rsp, -8)),
    x86.Movq(x86.Imm(1), x86.Reg(Rax)),
    x86.Xorq(x86.Deref(Rsp, -8), x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]

  let assert Ok(x86.Block(body_actual)) = dict.get(p.body, "start")
  body_actual |> should.equal(body_expected)
}
