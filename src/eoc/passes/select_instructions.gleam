// select_instructions (convert C-like into x86 instructions)
//    Cif -> x86var_if
import gleam/dict
import gleam/list

import eoc/langs/c_loop as c
import eoc/langs/l_while as l
import eoc/langs/x86_base.{Rax}
import eoc/langs/x86_var_if as x86

pub fn select_instructions(input: c.CProgram) -> x86.X86Program {
  let blocks =
    dict.map_values(input.body, fn(_, tail) {
      let block = x86.new_block()
      x86.Block(..block, body: select_tail(tail))
    })
  x86.X86Program(..x86.new_program(), body: blocks)
}

fn select_atm(input: c.Atm) -> x86.Arg {
  case input {
    c.Int(i) -> x86.Imm(i)
    c.Variable(v) -> x86.Var(v)
    c.Bool(bool) ->
      case bool {
        True -> x86.Imm(1)
        False -> x86.Imm(0)
      }
    c.Void -> x86.Imm(0)
  }
}

// var = (+ atm1 atm2)
// -->
// movq arg1, var
// addq arg2, var
//
// var = (+ atm1 var)
// -->
// addq arg1, var
//
// var = (read)
// -->
// callq read_int
// movq %rax, var
fn select_stmt(input: c.Stmt) -> List(x86.Instr) {
  case input {
    c.Assign(v, c.Atom(atm)) -> [x86.Movq(select_atm(atm), x86.Var(v))]
    c.Assign(v, c.Prim(c.Read)) -> [
      x86.Callq("read_int", 0),
      x86.Movq(x86.Reg(Rax), x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Neg(c.Variable(v1)))) if v == v1 -> [
      x86.Negq(x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Neg(atm))) -> [
      x86.Movq(select_atm(atm), x86.Var(v)),
      x86.Negq(x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Plus(c.Variable(v1), b))) if v == v1 -> [
      x86.Addq(select_atm(b), x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Plus(a, c.Variable(v1)))) if v == v1 -> [
      x86.Addq(select_atm(a), x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Plus(a, b))) -> [
      x86.Movq(select_atm(a), x86.Var(v)),
      x86.Addq(select_atm(b), x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Minus(c.Variable(v1), b))) if v == v1 -> [
      x86.Subq(select_atm(b), x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Minus(a, c.Variable(v1)))) if v == v1 -> [
      x86.Negq(x86.Var(v)),
      x86.Addq(select_atm(a), x86.Var(v)),
    ]
    c.Assign(v, c.Prim(c.Minus(a, b))) -> [
      x86.Movq(select_atm(a), x86.Var(v)),
      x86.Subq(select_atm(b), x86.Var(v)),
    ]
    c.Assign(var:, expr: c.Prim(op: c.Not(a:))) -> [
      x86.Movq(select_atm(a), x86.Var(var)),
      x86.Xorq(x86.Imm(1), x86.Var(var)),
    ]
    c.Assign(var:, expr: c.Prim(op: c.Cmp(op:, a:, b:))) -> [
      x86.Cmpq(select_atm(b), select_atm(a)),
      x86.Set(convert_op_to_cc(op), x86_base.Al),
      x86.Movzbq(x86_base.Al, x86.Var(var)),
    ]
    c.ReadStmt -> [x86.Callq("read_int", 0)]
  }
}

fn select_tail(input: c.Tail) -> List(x86.Instr) {
  case input {
    c.Seq(s, t) -> list.append(select_stmt(s), select_tail(t))
    c.Return(c.Atom(atm)) -> [
      x86.Movq(select_atm(atm), x86.Reg(Rax)),
      x86.Jmp("conclusion"),
    ]
    c.Return(c.Prim(c.Read)) -> [
      x86.Callq("read_int", 0),
      x86.Jmp("conclusion"),
    ]
    c.Return(c.Prim(c.Neg(a))) -> [
      x86.Movq(select_atm(a), x86.Reg(Rax)),
      x86.Negq(x86.Reg(Rax)),
      x86.Jmp("conclusion"),
    ]
    c.Return(c.Prim(c.Plus(a, b))) -> [
      x86.Movq(select_atm(a), x86.Reg(Rax)),
      x86.Addq(select_atm(b), x86.Reg(Rax)),
      x86.Jmp("conclusion"),
    ]
    c.Return(c.Prim(c.Minus(a, b))) -> [
      x86.Movq(select_atm(a), x86.Reg(Rax)),
      x86.Subq(select_atm(b), x86.Reg(Rax)),
      x86.Jmp("conclusion"),
    ]
    c.Return(c.Prim(c.Cmp(_, _, _))) | c.Return(c.Prim(op: c.Not(_))) ->
      panic as "program returns boolean"
    c.Goto(label:) -> [x86.Jmp(label)]
    c.If(
      cond: c.Prim(c.Cmp(op:, a:, b:)),
      if_true: c.Goto(l1),
      if_false: c.Goto(l2),
    ) -> [
      x86.Cmpq(select_atm(b), select_atm(a)),
      x86.JmpIf(convert_op_to_cc(op), l1),
      x86.Jmp(l2),
    ]
    c.If(_, _, _) -> panic as "invalid if statement"
  }
}

fn convert_op_to_cc(op: l.Cmp) -> x86_base.Cc {
  case op {
    l.Eq -> x86_base.E
    l.Lt -> x86_base.L
    l.Lte -> x86_base.Le
    l.Gt -> x86_base.G
    l.Gte -> x86_base.Ge
  }
}
