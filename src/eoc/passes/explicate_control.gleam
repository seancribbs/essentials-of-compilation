import eoc/langs/c_if
import eoc/langs/l_mon_if
import gleam/dict
import gleam/int

// explicate_control (explicit execution order, graph with gotos)
//    LMonIf -> Cif

// (let ([y (let ([x 20])
//            (+ x (let ([x 22]) x)))])
//   y)
//
// (let ([y.3 (let ([x.2 20])
//              (let ([x.1 22])
//                (+ x.2 x.1)))])
//  y.3)
//
// start:
//   x.2 = 20
//   x.1 = 22
//   y.3 = (+ x.2 x.1)
//   return y.3;

pub fn explicate_control(input: l_mon_if.Program) -> c_if.CProgram {
  let #(tail, blocks) = explicate_tail(input.body, dict.new())
  c_if.CProgram(dict.new(), dict.insert(blocks, "start", tail))
}

fn explicate_tail(
  input: l_mon_if.Expr,
  blocks: Blocks,
) -> #(c_if.Tail, c_if.Blocks) {
  case input {
    l_mon_if.Atomic(l_mon_if.Var(v)) -> #(
      c_if.Return(c_if.Atom(c_if.Variable(v))),
      blocks,
    )
    l_mon_if.Atomic(l_mon_if.Int(i)) -> #(
      c_if.Return(c_if.Atom(c_if.Int(i))),
      blocks,
    )
    l_mon_if.Atomic(l_mon_if.Bool(b)) -> #(
      c_if.Return(c_if.Atom(c_if.Bool(b))),
      blocks,
    )
    l_mon_if.Let(v, b, e) -> {
      let #(tail, new_blocks) = explicate_tail(e, blocks)
      explicate_assign(b, v, tail, new_blocks)
    }
    l_mon_if.If(cond:, if_true:, if_false:) -> {
      let #(t1, b1) = explicate_tail(if_true, blocks)
      let #(f1, b2) = explicate_tail(if_false, b1)
      explicate_pred(cond, t1, f1, b2)
    }
    l_mon_if.Prim(l_mon_if.Read) -> {
      #(c_if.Return(c_if.Prim(c_if.Read)), blocks)
    }
    l_mon_if.Prim(l_mon_if.Negate(a)) -> {
      #(c_if.Return(c_if.Prim(c_if.Neg(convert_atm(a)))), blocks)
    }
    l_mon_if.Prim(l_mon_if.Minus(a, b)) -> {
      #(
        c_if.Return(c_if.Prim(c_if.Minus(convert_atm(a), convert_atm(b)))),
        blocks,
      )
    }
    l_mon_if.Prim(l_mon_if.Plus(a, b)) -> {
      #(
        c_if.Return(c_if.Prim(c_if.Plus(convert_atm(a), convert_atm(b)))),
        blocks,
      )
    }
    l_mon_if.Prim(op: l_mon_if.Cmp(op:, a:, b:)) -> #(
      c_if.Return(c_if.Prim(c_if.Cmp(op, convert_atm(a), convert_atm(b)))),
      blocks,
    )
    l_mon_if.Prim(op: l_mon_if.Not(value:)) -> #(
      c_if.Return(c_if.Prim(c_if.Not(convert_atm(value)))),
      blocks,
    )
  }
}

fn explicate_assign(
  expr: l_mon_if.Expr,
  v: String,
  cont: c_if.Tail,
  blocks: c_if.Blocks,
) -> #(c_if.Tail, c_if.Blocks) {
  case expr {
    // v := variable | int
    // ...cont
    l_mon_if.Atomic(a) -> #(
      c_if.Seq(c_if.Assign(v, c_if.Atom(convert_atm(a))), cont),
      blocks,
    )
    // v := read()
    // ...cont
    l_mon_if.Prim(l_mon_if.Read) -> {
      #(c_if.Seq(c_if.Assign(v, c_if.Prim(c_if.Read)), cont), blocks)
    }
    // v := - a
    // ...cont
    l_mon_if.Prim(l_mon_if.Negate(a)) -> {
      #(
        c_if.Seq(c_if.Assign(v, c_if.Prim(c_if.Neg(convert_atm(a)))), cont),
        blocks,
      )
    }
    // v := a - b
    // ...cont
    l_mon_if.Prim(l_mon_if.Minus(a, b)) -> {
      #(
        c_if.Seq(
          c_if.Assign(v, c_if.Prim(c_if.Minus(convert_atm(a), convert_atm(b)))),
          cont,
        ),
        blocks,
      )
    }
    // v := a + b
    // ...cont
    l_mon_if.Prim(l_mon_if.Plus(a, b)) -> {
      #(
        c_if.Seq(
          c_if.Assign(v, c_if.Prim(c_if.Plus(convert_atm(a), convert_atm(b)))),
          cont,
        ),
        blocks,
      )
    }
    // v := a [op] b
    // ...cont
    l_mon_if.Prim(op: l_mon_if.Cmp(op:, a:, b:)) -> #(
      c_if.Seq(
        c_if.Assign(v, c_if.Prim(c_if.Cmp(op, convert_atm(a), convert_atm(b)))),
        cont,
      ),
      blocks,
    )

    // v := !value
    // ...cont
    l_mon_if.Prim(op: l_mon_if.Not(value:)) -> {
      #(
        c_if.Seq(c_if.Assign(v, c_if.Prim(c_if.Not(convert_atm(value)))), cont),
        blocks,
      )
    }
    // v1 := ...b
    // v := ...e
    // ...cont
    l_mon_if.Let(v1, b, e) -> {
      let #(cont1, b1) = explicate_assign(e, v, cont, blocks)
      explicate_assign(b, v1, cont1, b1)
    }
    //
    // block_1:
    //   ...cont
    l_mon_if.If(cond:, if_true:, if_false:) -> {
      let #(new_cont, new_blocks) = create_block(cont, blocks)
      let #(t1, b1) = explicate_assign(if_true, v, new_cont, new_blocks)
      let #(f1, b2) = explicate_assign(if_false, v, new_cont, b1)
      explicate_pred(cond, t1, f1, b2)
    }
  }
}

fn explicate_pred(
  cond: l_mon_if.Expr,
  if_true: c_if.Tail,
  if_false: c_if.Tail,
  blocks: c_if.Blocks,
) -> #(c_if.Tail, c_if.Blocks) {
  case cond {
    l_mon_if.Atomic(l_mon_if.Var(v)) -> todo
    l_mon_if.Let(var:, binding:, expr:) -> todo
    l_mon_if.Prim(l_mon_if.Not(_)) -> todo
    l_mon_if.Prim(l_mon_if.Cmp(op:, a:, b:)) -> {
      let #(thn_block, b1) = create_block(if_true, blocks)
      let #(els_block, b2) = create_block(if_false, b1)
      #(
        c_if.If(
          c_if.Prim(c_if.Cmp(op, convert_atm(a), convert_atm(b))),
          thn_block,
          els_block,
        ),
        b2,
      )
    }

    l_mon_if.If(cond: c_inner, if_true: t_inner, if_false: f_inner) -> {
      let #(thn_block, b1) = create_block(if_true, blocks)
      let #(els_block, b2) = create_block(if_false, b1)
      let #(t1, b3) = explicate_pred(t_inner, thn_block, els_block, b2)
      let #(f1, b4) = explicate_pred(f_inner, thn_block, els_block, b3)
      explicate_pred(c_inner, t1, f1, b4)
    }

    l_mon_if.Atomic(value: l_mon_if.Bool(value:)) -> {
      case value {
        True -> #(if_true, blocks)
        False -> #(if_false, blocks)
      }
    }
    _ -> panic as "explicate_pred unhandled case"
    // l_mon_if.Atomic(value: l_mon_if.Int(value:)) -> todo
    // l_mon_if.Prim(op: l_mon_if.Minus(a:, b:)) -> todo
    // l_mon_if.Prim(op: l_mon_if.Negate(value:)) -> todo
    // l_mon_if.Prim(op: l_mon_if.Plus(a:, b:)) -> todo
    // l_mon_if.Prim(op: l_mon_if.Read) -> todo
  }
}

fn create_block(
  tail: c_if.Tail,
  blocks: c_if.Blocks,
) -> #(c_if.Tail, c_if.Blocks) {
  case tail {
    c_if.Goto(_) -> #(tail, blocks)
    _ -> {
      let new_index = dict.size(blocks) + 1
      let new_label = "block_" <> int.to_string(new_index)
      #(c_if.Goto(new_label), dict.insert(blocks, new_label, tail))
    }
  }
}

fn convert_atm(input: l_mon_if.Atm) -> c_if.Atm {
  case input {
    l_mon_if.Int(i) -> c_if.Int(i)
    l_mon_if.Var(v) -> c_if.Variable(v)
    l_mon_if.Bool(b) -> c_if.Bool(b)
  }
}
