import gleam/erlang
import gleam/int
import gleam/result
import gleam/string

pub type PrimOp {
  Read
  Negate(value: Expr)
  Plus(a: Expr, b: Expr)
  Minus(a: Expr, b: Expr)
}

pub type Expr {
  Int(value: Int)
  Prim(op: PrimOp)
}

pub type Program {
  Program(body: Expr)
}

pub fn interpret(p: Program) -> Int {
  interpret_exp(p.body)
}

fn interpret_exp(e: Expr) -> Int {
  case e {
    Int(value) -> value
    Prim(op) -> interpret_op(op)
  }
}

fn interpret_op(op: PrimOp) -> Int {
  case op {
    Minus(a, b) -> interpret_exp(a) - interpret_exp(b)
    Negate(v) -> -interpret_exp(v)
    Plus(a, b) -> interpret_exp(a) + interpret_exp(b)
    Read -> read_int()
  }
}

fn read_int() -> Int {
  let result = {
    erlang.get_line(">")
    |> result.map_error(fn(_) { Nil })
    |> result.try(fn(line) { line |> string.trim() |> int.parse() })
  }

  case result {
    Error(_) -> panic as "could not read an int from stdin"
    Ok(i) -> i
  }
}

pub fn partial(p: Program) -> Program {
  Program(partial_exp(p.body))
}

fn partial_exp(e: Expr) -> Expr {
  case e {
    Int(i) -> Int(i)
    Prim(Read) -> Prim(Read)
    Prim(Negate(e1)) -> partial_neg(partial_exp(e1))
    Prim(Plus(e1, e2)) -> partial_add(partial_exp(e1), partial_exp(e2))
    Prim(Minus(e1, e2)) -> partial_sub(partial_exp(e1), partial_exp(e2))
  }
}

fn partial_neg(e: Expr) -> Expr {
  case e {
    Int(v) -> Int(-v)
    e1 -> Prim(Negate(e1))
  }
}

fn partial_add(e1: Expr, e2: Expr) -> Expr {
  case e1, e2 {
    Int(a), Int(b) -> Int(a + b)
    _, _ -> Prim(Plus(e1, e2))
  }
}

fn partial_sub(e1: Expr, e2: Expr) -> Expr {
  case e1, e2 {
    Int(a), Int(b) -> Int(a - b)
    _, _ -> Prim(Minus(e1, e2))
  }
}
