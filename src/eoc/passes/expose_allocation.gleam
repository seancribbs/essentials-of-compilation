import eoc/langs/l_alloc as la
import eoc/langs/l_tup as l
import gleam/int
import gleam/list
import gleam/pair

pub fn expose_allocation(input: l.Program) -> la.Program {
  input.body
  |> expose_expr(1)
  |> pair.first
  |> la.Program
}

fn expose_expr(e: l.Expr, counter: Int) -> #(la.Expr, Int) {
  case e {
    l.Bool(value:) -> #(la.Bool(value), counter)
    l.Int(value:) -> #(la.Int(value), counter)
    l.Var(name:) -> #(la.Var(name), counter)
    l.Begin(stmts:, result:) -> {
      let #(counter1, stmts) =
        list.map_fold(stmts, counter, fn(c, e) { pair.swap(expose_expr(e, c)) })
      let #(result, counter2) = expose_expr(result, counter1)
      #(la.Begin(stmts:, result:), counter2)
    }
    l.HasType(value: l.Prim(l.Vector(es)), t:) -> {
      let len = list.length(es)
      let bytes = { len + 1 } * 8
      let #(c1, exprs) =
        list.map_fold(es, counter, fn(c, e) {
          let #(en, cn) = expose_expr(e, c)
          let #(var, cn) = fresh_var("vecinit", cn)
          #(cn, #(var, en))
        })
      let #(alloc, c2) = fresh_var("alloc", c1)
      let #(set_fields, c3, _) =
        list.fold_right(exprs, #(la.Var(alloc), c2, len - 1), fn(acc, varexp) {
          let nested = acc.0
          let field = acc.2
          let #(ignore, count) = fresh_var("_", acc.1)
          let set =
            la.Prim(la.VectorSet(
              v: la.Var(alloc),
              index: la.Int(field),
              value: la.Var(varexp.0),
            ))
          #(la.Let(ignore, set, nested), count, field - 1)
        })
      let #(ignore, c4) = fresh_var("_", c3)
      let gc =
        la.If(
          condition: la.Prim(la.Cmp(
            l.Lt,
            la.Prim(la.Plus(la.GlobalValue("free_ptr"), la.Int(bytes))),
            la.GlobalValue("fromspace_end"),
          )),
          if_true: la.Prim(la.Void),
          if_false: la.Collect(bytes),
        )
      let gc_alloc_set =
        la.Let(ignore, gc, la.Let(alloc, la.Allocate(len, t), set_fields))

      #(
        list.fold_right(exprs, gc_alloc_set, fn(acc, varexpr) {
          la.Let(varexpr.0, varexpr.1, acc)
        }),
        c4,
      )
    }
    l.HasType(value: _, t: _) -> panic as "unexpected type wrapper"
    l.If(condition:, if_true:, if_false:) -> {
      let #(condition, c1) = expose_expr(condition, counter)
      let #(if_true, c2) = expose_expr(if_true, c1)
      let #(if_false, c3) = expose_expr(if_false, c2)
      #(la.If(condition:, if_true:, if_false:), c3)
    }
    l.Let(var:, binding:, expr:) -> {
      let #(binding, c1) = expose_expr(binding, counter)
      let #(expr, c2) = expose_expr(expr, c1)
      #(la.Let(var, binding, expr), c2)
    }
    l.Prim(op:) -> {
      let #(op, c1) = expose_op(op, counter)
      #(la.Prim(op), c1)
    }
    l.SetBang(var:, value:) -> {
      let #(value, c1) = expose_expr(value, counter)
      #(la.SetBang(var:, value:), c1)
    }
    l.WhileLoop(condition:, body:) -> {
      let #(condition, c1) = expose_expr(condition, counter)
      let #(body, c2) = expose_expr(body, c1)
      #(la.WhileLoop(condition:, body:), c2)
    }
  }
}

fn expose_op(op: l.PrimOp, counter: Int) -> #(la.PrimOp, Int) {
  case op {
    l.Vector(fields: _) -> panic as "untagged vector initialization"
    l.Read -> #(la.Read, counter)
    l.Void -> #(la.Void, counter)
    l.And(a:, b:) -> {
      let #(a, c1) = expose_expr(a, counter)
      let #(b, c2) = expose_expr(b, c1)
      #(la.And(a, b), c2)
    }
    l.Cmp(op:, a:, b:) -> {
      let #(a, c1) = expose_expr(a, counter)
      let #(b, c2) = expose_expr(b, c1)
      #(la.Cmp(op, a, b), c2)
    }
    l.Minus(a:, b:) -> {
      let #(a, c1) = expose_expr(a, counter)
      let #(b, c2) = expose_expr(b, c1)
      #(la.Minus(a, b), c2)
    }
    l.Negate(value:) -> {
      let #(value, c1) = expose_expr(value, counter)
      #(la.Negate(value), c1)
    }
    l.Not(a:) -> {
      let #(value, c1) = expose_expr(a, counter)
      #(la.Not(value), c1)
    }
    l.Or(a:, b:) -> {
      let #(a, c1) = expose_expr(a, counter)
      let #(b, c2) = expose_expr(b, c1)
      #(la.Or(a, b), c2)
    }
    l.Plus(a:, b:) -> {
      let #(a, c1) = expose_expr(a, counter)
      let #(b, c2) = expose_expr(b, c1)
      #(la.Plus(a, b), c2)
    }
    l.VectorLength(v:) -> {
      {
        let #(v, c1) = expose_expr(v, counter)
        #(la.VectorLength(v), c1)
      }
    }
    l.VectorRef(v:, index:) -> {
      let #(v, c1) = expose_expr(v, counter)
      let #(index, c2) = expose_expr(index, c1)
      #(la.VectorRef(v, index), c2)
    }
    l.VectorSet(v:, index:, value:) -> {
      let #(v, c1) = expose_expr(v, counter)
      let #(index, c2) = expose_expr(index, c1)
      let #(value, c3) = expose_expr(value, c2)
      #(la.VectorSet(v, index, value), c3)
    }
  }
}

fn fresh_var(prefix: String, counter: Int) -> #(String, Int) {
  #(prefix <> int.to_string(counter), counter + 1)
}
