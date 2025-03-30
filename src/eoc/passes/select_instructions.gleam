// select_instructions (convert Lvar into sequences instructions)
//    Cvar -> x86var
import gleam/dict
import gleam/list

import eoc/langs/c_var
import eoc/langs/x86_var

pub fn select_instructions(input: c_var.CProgram) -> x86_var.X86Program {
  let blocks =
    dict.map_values(input.body, fn(_, tail) {
      x86_var.Block(select_tail(tail), [])
    })
  x86_var.X86Program(blocks)
}

fn select_atm(input: c_var.Atm) -> x86_var.Arg {
  case input {
    c_var.Int(i) -> x86_var.Imm(i)
    c_var.Variable(v) -> x86_var.Var(v)
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
fn select_stmt(input: c_var.Stmt) -> List(x86_var.Instr) {
  case input {
    c_var.Assign(v, c_var.Atom(atm)) -> [
      x86_var.Movq(select_atm(atm), x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Read)) -> [
      x86_var.Callq("read_int", 0),
      x86_var.Movq(x86_var.Reg(x86_var.Rax), x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Neg(c_var.Variable(v1)))) if v == v1 -> [
      x86_var.Negq(x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Neg(atm))) -> [
      x86_var.Movq(select_atm(atm), x86_var.Var(v)),
      x86_var.Negq(x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Plus(c_var.Variable(v1), b))) if v == v1 -> [
      x86_var.Addq(select_atm(b), x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Plus(a, c_var.Variable(v1)))) if v == v1 -> [
      x86_var.Addq(select_atm(a), x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Plus(a, b))) -> [
      x86_var.Movq(select_atm(a), x86_var.Var(v)),
      x86_var.Addq(select_atm(b), x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Minus(c_var.Variable(v1), b))) if v == v1 -> [
      x86_var.Subq(select_atm(b), x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Minus(a, c_var.Variable(v1)))) if v == v1 -> [
      x86_var.Negq(x86_var.Var(v)),
      x86_var.Addq(select_atm(a), x86_var.Var(v)),
    ]
    c_var.Assign(v, c_var.Prim(c_var.Minus(a, b))) -> [
      x86_var.Movq(select_atm(a), x86_var.Var(v)),
      x86_var.Subq(select_atm(b), x86_var.Var(v)),
    ]
  }
}

fn select_tail(input: c_var.Tail) -> List(x86_var.Instr) {
  case input {
    c_var.Seq(s, t) -> list.append(select_stmt(s), select_tail(t))
    c_var.Return(c_var.Atom(atm)) -> [
      x86_var.Movq(select_atm(atm), x86_var.Reg(x86_var.Rax)),
      x86_var.Jmp("conclusion"),
    ]
    c_var.Return(c_var.Prim(c_var.Read)) -> [
      x86_var.Callq("read_int", 0),
      x86_var.Jmp("conclusion"),
    ]
    c_var.Return(c_var.Prim(c_var.Neg(a))) -> [
      x86_var.Movq(select_atm(a), x86_var.Reg(x86_var.Rax)),
      x86_var.Negq(x86_var.Reg(x86_var.Rax)),
      x86_var.Jmp("conclusion"),
    ]
    c_var.Return(c_var.Prim(c_var.Plus(a, b))) -> [
      x86_var.Movq(select_atm(a), x86_var.Reg(x86_var.Rax)),
      x86_var.Addq(select_atm(b), x86_var.Reg(x86_var.Rax)),
      x86_var.Jmp("conclusion"),
    ]
    c_var.Return(c_var.Prim(c_var.Minus(a, b))) -> [
      x86_var.Movq(select_atm(a), x86_var.Reg(x86_var.Rax)),
      x86_var.Subq(select_atm(b), x86_var.Reg(x86_var.Rax)),
      x86_var.Jmp("conclusion"),
    ]
  }
}
