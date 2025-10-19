// select_instructions (convert C-like into x86 instructions)
//    Cif -> x86var_if
import gleam/dict
import gleam/int
import gleam/list

import eoc/langs/c_tup as c
import eoc/langs/l_tup as l
import eoc/langs/x86_base.{R11, Rax}
import eoc/langs/x86_global as x86

pub fn select_instructions(input: c.CProgram) -> x86.X86Program {
  let #(body, types) =
    dict.fold(input.body, #(dict.new(), dict.new()), fn(acc, block_name, tail) {
      let #(blocks, types) = acc
      let #(body, new_types) = select_tail(tail)
      let block = x86.Block(..x86.new_block(), body:)
      #(dict.insert(blocks, block_name, block), dict.merge(types, new_types))
    })
  x86.X86Program(..x86.new_program(), body:, types:)
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
fn select_stmt(input: c.Stmt) -> #(List(x86.Instr), dict.Dict(String, l.Type)) {
  let types = dict.new()
  case input {
    c.Assign(v, c.Atom(atm)) -> #(
      [x86.Movq(select_atm(atm), x86.Var(v))],
      types,
    )
    c.Assign(v, c.Prim(c.Read)) -> #(
      [
        x86.Callq("read_int", 0),
        x86.Movq(x86.Reg(Rax), x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Neg(c.Variable(v1)))) if v == v1 -> #(
      [
        x86.Negq(x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Neg(atm))) -> #(
      [
        x86.Movq(select_atm(atm), x86.Var(v)),
        x86.Negq(x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Plus(c.Variable(v1), b))) if v == v1 -> #(
      [
        x86.Addq(select_atm(b), x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Plus(a, c.Variable(v1)))) if v == v1 -> #(
      [
        x86.Addq(select_atm(a), x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Plus(a, b))) -> #(
      [
        x86.Movq(select_atm(a), x86.Var(v)),
        x86.Addq(select_atm(b), x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Minus(c.Variable(v1), b))) if v == v1 -> #(
      [
        x86.Subq(select_atm(b), x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Minus(a, c.Variable(v1)))) if v == v1 -> #(
      [
        x86.Negq(x86.Var(v)),
        x86.Addq(select_atm(a), x86.Var(v)),
      ],
      types,
    )
    c.Assign(v, c.Prim(c.Minus(a, b))) -> #(
      [
        x86.Movq(select_atm(a), x86.Var(v)),
        x86.Subq(select_atm(b), x86.Var(v)),
      ],
      types,
    )
    c.Assign(var:, expr: c.Prim(op: c.Not(a:))) -> #(
      [
        x86.Movq(select_atm(a), x86.Var(var)),
        x86.Xorq(x86.Imm(1), x86.Var(var)),
      ],
      types,
    )
    c.Assign(var:, expr: c.Prim(op: c.Cmp(op:, a:, b:))) -> #(
      [
        x86.Cmpq(select_atm(b), select_atm(a)),
        x86.Set(convert_op_to_cc(op), x86_base.Al),
        x86.Movzbq(x86_base.Al, x86.Var(var)),
      ],
      types,
    )
    c.ReadStmt -> #([x86.Callq("read_int", 0)], types)
    c.Assign(var:, expr: c.Allocate(amount:, t:)) -> #(
      [
        x86.Movq(x86.Global("free_ptr"), x86.Reg(R11)),
        x86.Addq(x86.Imm(8 * { amount + 1 }), x86.Global("free_ptr")),
        x86.Movq(x86.Imm(compute_tag(amount, t)), x86.Deref(R11, 0)),
        x86.Movq(x86.Reg(R11), x86.Var(var)),
      ],
      dict.insert(types, var, t),
    )
    c.Assign(var:, expr: c.GlobalValue(var: gvar)) -> #(
      [
        x86.Movq(x86.Global(gvar), x86.Var(var)),
      ],
      types,
    )
    c.Assign(var:, expr: c.Prim(op: c.VectorLength(v:))) -> {
      let assert c.Variable(varname) = v
      #(
        [
          x86.Movq(x86.Var(varname), x86.Reg(R11)),
          x86.Movq(x86.Deref(R11, 0), x86.Reg(Rax)),
          x86.Sarq(x86.Imm(1), x86.Reg(Rax)),
          x86.Andq(x86.Imm(63), x86.Reg(Rax)),
          x86.Movq(x86.Reg(Rax), x86.Var(var)),
        ],
        types,
      )
    }
    c.Assign(var:, expr: c.Prim(op: c.VectorRef(v:, index:))) -> {
      let assert c.Variable(varname) = v
      let assert c.Int(n) = index
      #(
        [
          x86.Movq(x86.Var(varname), x86.Reg(R11)),
          x86.Movq(x86.Deref(R11, 8 * { n + 1 }), x86.Var(var)),
        ],
        types,
      )
    }
    c.Assign(var:, expr: c.Prim(op: c.VectorSet(v:, index:, value:))) -> {
      let assert c.Variable(varname) = v
      let assert c.Int(n) = index
      #(
        [
          x86.Movq(x86.Var(varname), x86.Reg(R11)),
          x86.Movq(select_atm(value), x86.Deref(R11, 8 * { n + 1 })),
          x86.Movq(x86.Imm(0), x86.Var(var)),
        ],
        types,
      )
    }
    c.VectorSetStmt(v:, index:, value:) -> {
      let assert c.Variable(varname) = v
      let assert c.Int(n) = index
      #(
        [
          x86.Movq(x86.Var(varname), x86.Reg(R11)),
          x86.Movq(select_atm(value), x86.Deref(R11, 8 * { n + 1 })),
        ],
        types,
      )
    }
    c.Collect(amount:) -> #(
      [
        x86.Movq(x86.Reg(x86_base.R15), x86.Reg(x86_base.Rdi)),
        x86.Movq(x86.Imm(amount), x86.Reg(x86_base.Rsi)),
        x86.Callq("collect", 2),
      ],
      types,
    )
  }
}

fn select_tail(input: c.Tail) -> #(List(x86.Instr), dict.Dict(String, l.Type)) {
  let types = dict.new()
  case input {
    c.Seq(s, t) -> {
      let #(s_instrs, s_types) = select_stmt(s)
      let #(t_instrs, t_types) = select_tail(t)
      #(list.append(s_instrs, t_instrs), dict.merge(s_types, t_types))
    }
    c.Return(c.Atom(atm)) -> #(
      [
        x86.Movq(select_atm(atm), x86.Reg(Rax)),
        x86.Jmp("conclusion"),
      ],
      types,
    )
    c.Return(c.Prim(c.Read)) -> #(
      [
        x86.Callq("read_int", 0),
        x86.Jmp("conclusion"),
      ],
      types,
    )
    c.Return(c.Prim(c.Neg(a))) -> #(
      [
        x86.Movq(select_atm(a), x86.Reg(Rax)),
        x86.Negq(x86.Reg(Rax)),
        x86.Jmp("conclusion"),
      ],
      types,
    )
    c.Return(c.Prim(c.Plus(a, b))) -> #(
      [
        x86.Movq(select_atm(a), x86.Reg(Rax)),
        x86.Addq(select_atm(b), x86.Reg(Rax)),
        x86.Jmp("conclusion"),
      ],
      types,
    )
    c.Return(c.Prim(c.Minus(a, b))) -> #(
      [
        x86.Movq(select_atm(a), x86.Reg(Rax)),
        x86.Subq(select_atm(b), x86.Reg(Rax)),
        x86.Jmp("conclusion"),
      ],
      types,
    )
    c.Return(c.Prim(c.Cmp(_, _, _))) | c.Return(c.Prim(op: c.Not(_))) ->
      panic as "program returns boolean"
    c.Goto(label:) -> #([x86.Jmp(label)], types)
    c.If(
      cond: c.Prim(c.Cmp(op:, a:, b:)),
      if_true: c.Goto(l1),
      if_false: c.Goto(l2),
    ) -> #(
      [
        x86.Cmpq(select_atm(b), select_atm(a)),
        x86.JmpIf(convert_op_to_cc(op), l1),
        x86.Jmp(l2),
      ],
      types,
    )
    c.If(_, _, _) -> panic as "invalid if statement"
    c.Return(a: c.Prim(op: c.VectorLength(v:))) -> {
      let assert c.Variable(varname) = v
      #(
        [
          x86.Movq(x86.Var(varname), x86.Reg(R11)),
          x86.Movq(x86.Deref(R11, 0), x86.Reg(Rax)),
          x86.Sarq(x86.Imm(1), x86.Reg(Rax)),
          x86.Andq(x86.Imm(63), x86.Reg(Rax)),
          x86.Jmp("conclusion"),
        ],
        types,
      )
    }
    c.Return(a: c.Prim(op: c.VectorRef(v:, index:))) -> {
      let assert c.Variable(varname) = v
      let assert c.Int(n) = index
      #(
        [
          x86.Movq(x86.Var(varname), x86.Reg(R11)),
          x86.Movq(x86.Deref(R11, 8 * { n + 1 }), x86.Reg(Rax)),
          x86.Jmp("conclusion"),
        ],
        types,
      )
    }
    c.Return(a: c.Prim(op: c.VectorSet(v: _, index: _, value: _))) ->
      panic as "invalid vector-set! in tail position"
    c.Return(a: c.Allocate(amount: _, t: _))
    | c.Return(a: c.GlobalValue(var: _)) ->
      panic as "runtime/gc internal in tail position"
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

pub fn compute_tag(amount: Int, t: l.Type) -> Int {
  let assert l.VectorT(fields) = t
  let mask =
    list.fold(fields, #(0, 0), fn(acc: #(Int, Int), f: l.Type) {
      let #(field_count, bits) = acc
      let field_mask =
        case f {
          l.VectorT(_) -> 1
          _ -> 0
        }
        |> int.bitwise_shift_left(field_count)
      #(field_count + 1, int.bitwise_or(bits, field_mask))
    }).1

  let bin = <<
    0:size(7),
    mask:size(50),
    amount:size(6),
    0:size(1),
  >>
  let assert <<tag:size(64)>> = bin
  tag
}
