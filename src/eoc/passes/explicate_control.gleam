import eoc/langs/c_loop as c
import eoc/langs/l_mon_while as l_mon
import eoc/langs/l_while as l
import gleam/dict
import gleam/int
import gleam/list

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

pub fn explicate_control(input: l_mon.Program) -> c.CProgram {
  let #(tail, blocks) = explicate_tail(input.body, dict.new())
  c.CProgram(dict.new(), dict.insert(blocks, "start", tail))
}

fn explicate_tail(input: l_mon.Expr, blocks: c.Blocks) -> #(c.Tail, c.Blocks) {
  case input {
    l_mon.Atomic(l_mon.Var(v)) -> #(c.Return(c.Atom(c.Variable(v))), blocks)
    l_mon.Atomic(l_mon.Int(i)) -> #(c.Return(c.Atom(c.Int(i))), blocks)
    l_mon.Atomic(l_mon.Bool(b)) -> #(c.Return(c.Atom(c.Bool(b))), blocks)
    l_mon.Atomic(l_mon.Void) -> #(c.Return(c.Atom(c.Void)), blocks)
    l_mon.Let(v, b, e) -> {
      let #(tail, new_blocks) = explicate_tail(e, blocks)
      explicate_assign(b, v, tail, new_blocks)
    }
    l_mon.If(cond:, if_true:, if_false:) -> {
      let #(t1, b1) = explicate_tail(if_true, blocks)
      let #(f1, b2) = explicate_tail(if_false, b1)
      explicate_pred(cond, t1, f1, b2)
    }
    l_mon.Prim(l_mon.Read) -> {
      #(c.Return(c.Prim(c.Read)), blocks)
    }
    l_mon.Prim(l_mon.Negate(a)) -> {
      #(c.Return(c.Prim(c.Neg(convert_atm(a)))), blocks)
    }
    l_mon.Prim(l_mon.Minus(a, b)) -> {
      #(c.Return(c.Prim(c.Minus(convert_atm(a), convert_atm(b)))), blocks)
    }
    l_mon.Prim(l_mon.Plus(a, b)) -> {
      #(c.Return(c.Prim(c.Plus(convert_atm(a), convert_atm(b)))), blocks)
    }
    l_mon.Prim(op: l_mon.Cmp(op:, a:, b:)) -> #(
      c.Return(c.Prim(c.Cmp(op, convert_atm(a), convert_atm(b)))),
      blocks,
    )
    l_mon.Prim(op: l_mon.Not(value:)) -> #(
      c.Return(c.Prim(c.Not(convert_atm(value)))),
      blocks,
    )
    l_mon.GetBang(var:) -> #(c.Return(c.Atom(c.Variable(var))), blocks)
    l_mon.SetBang(var:, value:) -> {
      let tail = c.Return(c.Atom(c.Void))
      explicate_assign(value, var, tail, blocks)
    }
    l_mon.Begin(stmts:, result:) -> {
      let #(tail, blocks1) = explicate_tail(result, blocks)
      list.fold_right(stmts, #(tail, blocks1), fn(acc, stmt) {
        explicate_effect(stmt, acc.0, acc.1)
      })
    }
    l_mon.WhileLoop(condition:, body:) -> {
      // Create a fresh label for the loop entrypoint
      let loop_label = create_label("loop", blocks)
      // Jump to the loop entrypoint at start and bottom of the loop body
      let loop_start = c.Goto(loop_label)
      // This is tail-position, and while loops have the void type
      let if_false = c.Return(c.Atom(c.Void))
      // The body does not affect the return type, so it is in effect position
      let #(if_true, blocks1) = explicate_effect(body, loop_start, blocks)
      // The loop condition is in predicate position, jumps to the return if false,
      // otherwise executes the body
      let #(loop_condition, blocks2) =
        explicate_pred(condition, if_true, if_false, blocks1)
      // Add the entrypoint of the loop to the blocks
      let blocks3 = dict.insert(blocks2, loop_label, loop_condition)
      // Jump into the loop
      #(loop_start, blocks3)
    }
  }
}

fn explicate_assign(
  expr: l_mon.Expr,
  v: String,
  cont: c.Tail,
  blocks: c.Blocks,
) -> #(c.Tail, c.Blocks) {
  case expr {
    // v := variable | int | boolean
    // ...cont
    l_mon.Atomic(a) -> #(
      c.Seq(c.Assign(v, c.Atom(convert_atm(a))), cont),
      blocks,
    )
    // v := read()
    // ...cont
    l_mon.Prim(l_mon.Read) -> {
      #(c.Seq(c.Assign(v, c.Prim(c.Read)), cont), blocks)
    }
    // v := - a
    // ...cont
    l_mon.Prim(l_mon.Negate(a)) -> {
      #(c.Seq(c.Assign(v, c.Prim(c.Neg(convert_atm(a)))), cont), blocks)
    }
    // v := a - b
    // ...cont
    l_mon.Prim(l_mon.Minus(a, b)) -> {
      #(
        c.Seq(
          c.Assign(v, c.Prim(c.Minus(convert_atm(a), convert_atm(b)))),
          cont,
        ),
        blocks,
      )
    }
    // v := a + b
    // ...cont
    l_mon.Prim(l_mon.Plus(a, b)) -> {
      #(
        c.Seq(c.Assign(v, c.Prim(c.Plus(convert_atm(a), convert_atm(b)))), cont),
        blocks,
      )
    }
    // v := a [op] b
    // ...cont
    l_mon.Prim(op: l_mon.Cmp(op:, a:, b:)) -> #(
      c.Seq(
        c.Assign(v, c.Prim(c.Cmp(op, convert_atm(a), convert_atm(b)))),
        cont,
      ),
      blocks,
    )

    // v := !value
    // ...cont
    l_mon.Prim(op: l_mon.Not(value:)) -> {
      #(c.Seq(c.Assign(v, c.Prim(c.Not(convert_atm(value)))), cont), blocks)
    }
    // v1 := ...b
    // v := ...e
    // ...cont
    l_mon.Let(v1, b, e) -> {
      let #(cont1, b1) = explicate_assign(e, v, cont, blocks)
      explicate_assign(b, v1, cont1, b1)
    }
    //
    // block_1:
    //   ...cont
    l_mon.If(cond:, if_true:, if_false:) -> {
      let #(new_cont, new_blocks) = create_block(cont, blocks)
      let #(t1, b1) = explicate_assign(if_true, v, new_cont, new_blocks)
      let #(f1, b2) = explicate_assign(if_false, v, new_cont, b1)
      explicate_pred(cond, t1, f1, b2)
    }
    l_mon.GetBang(var:) -> #(
      c.Seq(c.Assign(v, c.Atom(c.Variable(var))), cont),
      blocks,
    )
    // v := (set! v1 e)
    // ...cont
    //
    // v1 := e
    // v := void
    // ...cont
    l_mon.SetBang(var:, value:) -> {
      let new_cont = c.Seq(c.Assign(v, c.Atom(c.Void)), cont)
      explicate_assign(value, var, new_cont, blocks)
    }
    l_mon.Begin(stmts:, result:) -> {
      let cont = explicate_assign(result, v, cont, blocks)
      list.fold_right(stmts, cont, fn(acc, stmt) {
        explicate_effect(stmt, acc.0, acc.1)
      })
    }
    l_mon.WhileLoop(condition:, body:) -> {
      // Create a fresh label for the loop entrypoint
      let loop_label = create_label("loop", blocks)
      // Jump to the loop entrypoint at start and bottom of the loop body
      let loop_start = c.Goto(loop_label)
      // This is assign-position, and while loops have the void type
      let #(if_false, blocks1) =
        explicate_assign(l_mon.Atomic(l_mon.Void), v, cont, blocks)
      // The body does not affect the return type, so it is in effect position
      let #(if_true, blocks2) = explicate_effect(body, loop_start, blocks1)
      // The loop condition is in predicate position, jumps to the return if false,
      // otherwise executes the body
      let #(loop_condition, blocks3) =
        explicate_pred(condition, if_true, if_false, blocks2)
      // Add the entrypoint of the loop to the blocks
      let blocks4 = dict.insert(blocks3, loop_label, loop_condition)
      // Jump into the loop
      #(loop_start, blocks4)
    }
  }
}

fn explicate_pred(
  cond: l_mon.Expr,
  if_true: c.Tail,
  if_false: c.Tail,
  blocks: c.Blocks,
) -> #(c.Tail, c.Blocks) {
  case cond {
    l_mon.Atomic(l_mon.Var(v)) | l_mon.GetBang(v) -> {
      let #(thn_block, b1) = create_block(if_true, blocks)
      let #(els_block, b2) = create_block(if_false, b1)
      #(
        c.If(
          c.Prim(c.Cmp(l.Eq, c.Variable(v), c.Bool(True))),
          thn_block,
          els_block,
        ),
        b2,
      )
    }

    l_mon.Atomic(value: l_mon.Bool(value:)) -> {
      case value {
        True -> #(if_true, blocks)
        False -> #(if_false, blocks)
      }
    }

    l_mon.Prim(l_mon.Not(arg)) -> {
      // Invert the branching on logical negation
      explicate_pred(l_mon.Atomic(arg), if_false, if_true, blocks)
    }

    l_mon.Let(var:, binding:, expr:) -> {
      let #(new_expr, b1) = explicate_pred(expr, if_true, if_false, blocks)
      explicate_assign(binding, var, new_expr, b1)
    }

    l_mon.Prim(l_mon.Cmp(op:, a:, b:)) -> {
      let #(thn_block, b1) = create_block(if_true, blocks)
      let #(els_block, b2) = create_block(if_false, b1)
      #(
        c.If(
          c.Prim(c.Cmp(op, convert_atm(a), convert_atm(b))),
          thn_block,
          els_block,
        ),
        b2,
      )
    }

    l_mon.If(cond: c_inner, if_true: t_inner, if_false: f_inner) -> {
      let #(thn_block, b1) = create_block(if_true, blocks)
      let #(els_block, b2) = create_block(if_false, b1)
      let #(t1, b3) = explicate_pred(t_inner, thn_block, els_block, b2)
      let #(f1, b4) = explicate_pred(f_inner, thn_block, els_block, b3)
      explicate_pred(c_inner, t1, f1, b4)
    }

    l_mon.Begin(stmts:, result:) -> {
      let #(tail, blocks1) = explicate_pred(result, if_true, if_false, blocks)
      list.fold_right(stmts, #(tail, blocks1), fn(acc, stmt) {
        explicate_effect(stmt, acc.0, acc.1)
      })
    }

    _ -> panic as "explicate_pred unhandled case"
    // l_mon.Atomic(value: l_mon.Int(value:)) -> todo
    // l_mon.Prim(op: l_mon.Minus(a:, b:)) -> todo
    // l_mon.Prim(op: l_mon.Negate(value:)) -> todo
    // l_mon.Prim(op: l_mon.Plus(a:, b:)) -> todo
    // l_mon.Prim(op: l_mon.Read) -> todo
    // l_mon.WhileLoop(condition:,body:) -> todo
    // l_mon.SetBang(var:, expr:) -> todo
  }
}

fn explicate_effect(
  expr: l_mon.Expr,
  cont: c.Tail,
  blocks: c.Blocks,
) -> #(c.Tail, c.Blocks) {
  case expr {
    l_mon.Prim(l_mon.Read) -> #(c.Seq(c.ReadStmt, cont), blocks)
    l_mon.Atomic(_) | l_mon.GetBang(_) | l_mon.Prim(_) -> #(cont, blocks)
    l_mon.SetBang(var:, value:) -> {
      explicate_assign(value, var, cont, blocks)
    }
    l_mon.Let(var:, binding:, expr:) -> {
      let #(tail, new_blocks) = explicate_effect(expr, cont, blocks)
      explicate_assign(binding, var, tail, new_blocks)
    }
    l_mon.Begin(stmts:, result:) -> {
      let tail = explicate_effect(result, cont, blocks)
      list.fold(stmts, tail, fn(acc, stmt) {
        explicate_effect(stmt, acc.0, acc.1)
      })
    }
    l_mon.If(cond:, if_true:, if_false:) -> {
      let #(new_cont, b1) = create_block(cont, blocks)
      let #(thn_block, b2) = explicate_effect(if_true, new_cont, b1)
      let #(els_block, b3) = explicate_effect(if_false, new_cont, b2)
      explicate_pred(cond, thn_block, els_block, b3)
    }
    l_mon.WhileLoop(condition:, body:) -> {
      // Create a fresh label for the loop entrypoint
      let loop_label = create_label("loop", blocks)
      // Jump to the loop entrypoint at start and bottom of the loop body
      let loop_start = c.Goto(loop_label)
      // This is effect-position, so just jump to the continuation at the end
      let #(if_false, blocks1) = create_block(cont, blocks)
      // The body does not affect the return type, so it is in effect position
      let #(if_true, blocks2) = explicate_effect(body, loop_start, blocks1)
      // The loop condition is in predicate position, jumps to the return if false,
      // otherwise executes the body
      let #(loop_condition, blocks3) =
        explicate_pred(condition, if_true, if_false, blocks2)
      // Add the entrypoint of the loop to the blocks
      let blocks4 = dict.insert(blocks3, loop_label, loop_condition)
      // Jump into the loop
      #(loop_start, blocks4)
    }
  }
}

fn create_label(prefix: String, blocks: c.Blocks) -> String {
  let new_index = dict.size(blocks) + 1
  prefix <> "_" <> int.to_string(new_index)
}

fn create_block(tail: c.Tail, blocks: c.Blocks) -> #(c.Tail, c.Blocks) {
  case tail {
    c.Goto(_) -> #(tail, blocks)
    _ -> {
      let new_label = create_label("block", blocks)
      #(c.Goto(new_label), dict.insert(blocks, new_label, tail))
    }
  }
}

fn convert_atm(input: l_mon.Atm) -> c.Atm {
  case input {
    l_mon.Int(i) -> c.Int(i)
    l_mon.Var(v) -> c.Variable(v)
    l_mon.Bool(b) -> c.Bool(b)
    l_mon.Void -> c.Void
  }
}
