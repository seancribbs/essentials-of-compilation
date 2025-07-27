import eoc/langs/l_while as lang
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string
import nibble.{type DeadEnd, type Parser, do, return}
import nibble/lexer

pub type Token {
  LParen
  RParen
  LBracket
  RBracket
  Integer(Int)
  Boolean(Bool)
  Keyword(Keyword)
  Cmp(lang.Cmp)
  Identifier(String)
}

pub type Keyword {
  Read
  Let
  Plus
  Minus
  And
  Or
  Not
  If
  SetBang
  Begin
  While
  Void
}

pub fn tokens(input: String) -> Result(List(lexer.Token(Token)), lexer.Error) {
  let l =
    lexer.simple([
      lexer.int(Integer),
      lexer.token("(", LParen),
      lexer.token(")", RParen),
      lexer.token("[", LBracket),
      lexer.token("]", RBracket),
      lexer.token("#t", Boolean(True)),
      lexer.token("#f", Boolean(False)),
      lexer.ignore(lexer.whitespace(Nil)),
      lexer.identifier(
        "[^0-9()\\[\\]{}\",'`;#|\\\\\\s]",
        "[^()\\[\\]{}\",'`;#|\\\\\\s]",
        set.new(),
        fn(text) {
          case text {
            "+" -> Keyword(Plus)
            "-" -> Keyword(Minus)
            ">=" -> Cmp(lang.Gte)
            "<=" -> Cmp(lang.Lte)
            ">" -> Cmp(lang.Gt)
            "<" -> Cmp(lang.Lt)
            "if" -> Keyword(If)
            "eq?" -> Cmp(lang.Eq)
            "set!" -> Keyword(SetBang)
            "read" -> Keyword(Read)
            "let" -> Keyword(Let)
            "and" -> Keyword(And)
            "or" -> Keyword(Or)
            "not" -> Keyword(Not)
            "begin" -> Keyword(Begin)
            "while" -> Keyword(While)
            "void" -> Keyword(Void)
            id -> Identifier(id)
          }
        },
      ),
    ])

  lexer.run(input, l)
}

pub fn parse(
  tokens: List(lexer.Token(Token)),
) -> Result(lang.Program, List(DeadEnd(Token, Nil))) {
  nibble.run(tokens, program())
}

fn program() -> Parser(lang.Program, Token, Nil) {
  use body <- do(expression())
  return(lang.Program(body:))
}

fn expression() -> Parser(lang.Expr, Token, Nil) {
  nibble.one_of([integer(), boolean(), variable(), nested()])
}

fn nested() -> Parser(lang.Expr, Token, Nil) {
  use _ <- do(nibble.token(LParen))
  use expr <- do(
    nibble.one_of([
      if_expr(),
      let_expr(),
      primitive(),
      begin_expr(),
      while_expr(),
      set_expr(),
    ]),
  )
  use _ <- do(nibble.token(RParen))
  return(expr)
}

fn begin_expr() -> Parser(lang.Expr, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Begin)))
  use exprs <- do(nibble.many1(expression()))
  let assert [result, ..stmts] = list.reverse(exprs)
  return(lang.Begin(list.reverse(stmts), result))
}

fn while_expr() -> Parser(lang.Expr, Token, Nil) {
  use _ <- do(nibble.token(Keyword(While)))
  use condition <- do(expression())
  use body <- do(expression())
  return(lang.WhileLoop(condition:, body:))
}

fn set_expr() -> Parser(lang.Expr, Token, Nil) {
  use _ <- do(nibble.token(Keyword(SetBang)))
  use var <- do(identifier())
  use value <- do(expression())
  return(lang.SetBang(var:, value:))
}

fn if_expr() -> Parser(lang.Expr, Token, Nil) {
  use _ <- do(nibble.token(Keyword(If)))
  use condition <- do(expression())
  use if_true <- do(expression())
  use if_false <- do(expression())

  return(lang.If(condition:, if_true:, if_false:))
}

fn let_expr() -> Parser(lang.Expr, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Let)))
  use _ <- do(nibble.token(LParen))
  use _ <- do(nibble.token(LBracket))
  use var <- do(identifier())
  use binding <- do(expression())
  use _ <- do(nibble.token(RBracket))
  use _ <- do(nibble.token(RParen))
  use expr <- do(expression())

  return(lang.Let(var:, binding:, expr:))
}

fn primitive() -> Parser(lang.Expr, Token, Nil) {
  use prim_op <- do(
    nibble.one_of([
      void_op(),
      read_op(),
      minus_op(),
      negate_op(),
      plus_op(),
      cmp_op(),
      and_op(),
      or_op(),
      not_op(),
    ]),
  )

  return(lang.Prim(prim_op))
}

fn read_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Read)))
  return(lang.Read)
}

fn void_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Void)))
  return(lang.Void)
}

fn minus_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Minus)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(lang.Minus(arg1, arg2))
}

fn negate_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Minus)))
  use expr <- do(expression())

  return(lang.Negate(expr))
}

fn plus_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Plus)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(lang.Plus(arg1, arg2))
}

fn cmp_inner() -> Parser(lang.Cmp, Token, Nil) {
  use tok <- nibble.take_map("expected comparison op")
  case tok {
    Cmp(op) -> Some(op)
    _ -> None
  }
}

fn cmp_op() -> Parser(lang.PrimOp, Token, Nil) {
  use op <- do(cmp_inner())
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(lang.Cmp(op, arg1, arg2))
}

fn and_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(And)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(lang.And(arg1, arg2))
}

fn or_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Or)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(lang.Or(arg1, arg2))
}

fn not_op() -> Parser(lang.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Not)))
  use expr <- do(expression())

  return(lang.Not(expr))
}

fn boolean() -> Parser(lang.Expr, Token, Nil) {
  use tok <- nibble.take_map("expected boolean")
  case tok {
    Boolean(b) -> Some(lang.Bool(b))
    _ -> None
  }
}

fn integer() -> Parser(lang.Expr, Token, Nil) {
  use tok <- nibble.take_map("expected integer")
  case tok {
    Integer(i) -> Some(lang.Int(i))
    _ -> None
  }
}

fn variable() -> Parser(lang.Expr, Token, Nil) {
  use id <- do(identifier())
  return(lang.Var(id))
}

fn identifier() -> Parser(String, Token, Nil) {
  use tok <- nibble.take_map("expected identifier")
  case tok {
    Identifier(v) -> Some(v)
    _ -> None
  }
}
