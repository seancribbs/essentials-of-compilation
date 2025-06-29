// select_instructions (convert C-like into x86 instructions)
//    Cif -> x86var_if
import gleam/dict
import gleam/list

import eoc/langs/c_if
import eoc/langs/l_if
import eoc/langs/x86_base.{Rax}
import eoc/langs/x86_var_if.{Block}

pub fn select_instructions(input: c_if.CProgram) -> x86_var_if.X86Program {
  let blocks =
    dict.map_values(input.body, fn(_, tail) {
      let block = x86_var_if.new_block()
      Block(..block, body: select_tail(tail))
    })
  x86_var_if.X86Program(..x86_var_if.new_program(), body: blocks)
}

fn select_atm(input: c_if.Atm) -> x86_var_if.Arg {
  case input {
    c_if.Int(i) -> x86_var_if.Imm(i)
    c_if.Variable(v) -> x86_var_if.Var(v)
    c_if.Bool(bool) ->
      case bool {
        True -> x86_var_if.Imm(1)
        False -> x86_var_if.Imm(0)
      }
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
fn select_stmt(input: c_if.Stmt) -> List(x86_var_if.Instr) {
  case input {
    c_if.Assign(v, c_if.Atom(atm)) -> [
      x86_var_if.Movq(select_atm(atm), x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Read)) -> [
      x86_var_if.Callq("read_int", 0),
      x86_var_if.Movq(x86_var_if.Reg(Rax), x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Neg(c_if.Variable(v1)))) if v == v1 -> [
      x86_var_if.Negq(x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Neg(atm))) -> [
      x86_var_if.Movq(select_atm(atm), x86_var_if.Var(v)),
      x86_var_if.Negq(x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Plus(c_if.Variable(v1), b))) if v == v1 -> [
      x86_var_if.Addq(select_atm(b), x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Plus(a, c_if.Variable(v1)))) if v == v1 -> [
      x86_var_if.Addq(select_atm(a), x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Plus(a, b))) -> [
      x86_var_if.Movq(select_atm(a), x86_var_if.Var(v)),
      x86_var_if.Addq(select_atm(b), x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Minus(c_if.Variable(v1), b))) if v == v1 -> [
      x86_var_if.Subq(select_atm(b), x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Minus(a, c_if.Variable(v1)))) if v == v1 -> [
      x86_var_if.Negq(x86_var_if.Var(v)),
      x86_var_if.Addq(select_atm(a), x86_var_if.Var(v)),
    ]
    c_if.Assign(v, c_if.Prim(c_if.Minus(a, b))) -> [
      x86_var_if.Movq(select_atm(a), x86_var_if.Var(v)),
      x86_var_if.Subq(select_atm(b), x86_var_if.Var(v)),
    ]
    c_if.Assign(var:, expr: c_if.Prim(op: c_if.Not(a:))) -> [
      x86_var_if.Movq(select_atm(a), x86_var_if.Var(var)),
      x86_var_if.Xorq(x86_var_if.Imm(1), x86_var_if.Var(var)),
    ]
    c_if.Assign(var:, expr: c_if.Prim(op: c_if.Cmp(op:, a:, b:))) -> [
      x86_var_if.Cmpq(select_atm(b), select_atm(a)),
      x86_var_if.Set(convert_op_to_cc(op), x86_base.Al),
      x86_var_if.Movzbq(x86_base.Al, x86_var_if.Var(var)),
    ]
  }
}

fn select_tail(input: c_if.Tail) -> List(x86_var_if.Instr) {
  case input {
    c_if.Seq(s, t) -> list.append(select_stmt(s), select_tail(t))
    c_if.Return(c_if.Atom(atm)) -> [
      x86_var_if.Movq(select_atm(atm), x86_var_if.Reg(Rax)),
      x86_var_if.Jmp("conclusion"),
    ]
    c_if.Return(c_if.Prim(c_if.Read)) -> [
      x86_var_if.Callq("read_int", 0),
      x86_var_if.Jmp("conclusion"),
    ]
    c_if.Return(c_if.Prim(c_if.Neg(a))) -> [
      x86_var_if.Movq(select_atm(a), x86_var_if.Reg(Rax)),
      x86_var_if.Negq(x86_var_if.Reg(Rax)),
      x86_var_if.Jmp("conclusion"),
    ]
    c_if.Return(c_if.Prim(c_if.Plus(a, b))) -> [
      x86_var_if.Movq(select_atm(a), x86_var_if.Reg(Rax)),
      x86_var_if.Addq(select_atm(b), x86_var_if.Reg(Rax)),
      x86_var_if.Jmp("conclusion"),
    ]
    c_if.Return(c_if.Prim(c_if.Minus(a, b))) -> [
      x86_var_if.Movq(select_atm(a), x86_var_if.Reg(Rax)),
      x86_var_if.Subq(select_atm(b), x86_var_if.Reg(Rax)),
      x86_var_if.Jmp("conclusion"),
    ]
    c_if.Return(c_if.Prim(c_if.Cmp(_, _, _)))
    | c_if.Return(c_if.Prim(op: c_if.Not(_))) ->
      panic as "program returns boolean"
    c_if.Goto(label:) -> [x86_var_if.Jmp(label)]
    c_if.If(
      cond: c_if.Prim(c_if.Cmp(op:, a:, b:)),
      if_true: c_if.Goto(l1),
      if_false: c_if.Goto(l2),
    ) -> [
      x86_var_if.Cmpq(select_atm(b), select_atm(a)),
      x86_var_if.JmpIf(convert_op_to_cc(op), l1),
      x86_var_if.Jmp(l2),
    ]
    c_if.If(_, _, _) -> panic as "invalid if statement"
  }
}

fn convert_op_to_cc(op: l_if.Cmp) -> x86_base.Cc {
  case op {
    l_if.Eq -> x86_base.E
    l_if.Lt -> x86_base.L
    l_if.Lte -> x86_base.Le
    l_if.Gt -> x86_base.G
    l_if.Gte -> x86_base.Ge
  }
}
