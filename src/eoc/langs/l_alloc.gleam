// import eoc/runtime
// import gleam/dict
// import gleam/list
// import gleam/pair
// import gleam/result

import eoc/langs/l_tup.{type Cmp, type Type}

pub type TypeError {
  TypeError(expected: Type, actual: Type, expression: Expr)
  VectorIndexOutOfBounds(actual: Int, size: Int)
  VectorIndexIsNotInteger(expr: Expr)
  UnboundVariable(name: String)
}

pub type PrimOp {
  Read
  Void
  Negate(value: Expr)
  Plus(a: Expr, b: Expr)
  Minus(a: Expr, b: Expr)
  Cmp(op: Cmp, a: Expr, b: Expr)
  And(a: Expr, b: Expr)
  Or(a: Expr, b: Expr)
  Not(a: Expr)
  // Vector(fields: List(Expr))
  VectorLength(v: Expr)
  VectorRef(v: Expr, index: Expr)
  VectorSet(v: Expr, index: Expr, value: Expr)
}

pub type Expr {
  Int(value: Int)
  Bool(value: Bool)
  Prim(op: PrimOp)
  Var(name: String)
  Let(var: String, binding: Expr, expr: Expr)
  If(condition: Expr, if_true: Expr, if_false: Expr)
  SetBang(var: String, value: Expr)
  Begin(stmts: List(Expr), result: Expr)
  WhileLoop(condition: Expr, body: Expr)
  HasType(value: Expr, t: Type)
  Collect(amount: Int)
  Allocate(amount: Int, t: Type)
  GlobalValue(name: String)
}

pub type Program {
  Program(body: Expr)
}
// fn dummy() {
//   Program(
//     Prim(VectorRef(
//       Prim(VectorRef(
//         Let(
//           "f5",
//           Let(
//             "f2",
//             Int(42),
//             Let(
//               "_4",
//               If(
//                 Prim(Cmp(
//                   Lt,
//                   Prim(Plus(GlobalValue("free_ptr"), Int(16))),
//                   GlobalValue("fromspace_end"),
//                 )),
//                 Prim(Void),
//                 Collect(16),
//               ),
//               Let(
//                 "alloc1",
//                 Allocate(1, VectorT([IntegerT])),
//                 Let(
//                   "_3",
//                   Prim(VectorSet(Var("alloc1"), Int(0), Var("f2"))),
//                   Var("alloc1"),
//                 ),
//               ),
//             ),
//           ),
//           Let(
//             "_7",
//             If(
//               Prim(Cmp(
//                 Lt,
//                 Prim(Plus(GlobalValue("free_ptr"), Int(16))),
//                 GlobalValue("fromspace_end"),
//               )),
//               Prim(Void),
//               Collect(16),
//             ),
//             Let(
//               "alloc0",
//               Allocate(1, VectorT([VectorT([IntegerT])])),
//               Let(
//                 "_6",
//                 Prim(VectorSet(Var("alloc0"), Int(0), Var("f5"))),
//                 Var("alloc0"),
//               ),
//             ),
//           ),
//         ),
//         Int(0),
//       )),
//       Int(0),
//     )),
//   )
// }
