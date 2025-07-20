import eoc/langs/l_if
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
  Cmp(l_if.Cmp)
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
}

pub fn tokens(input: String) -> Result(List(lexer.Token(Token)), lexer.Error) {
  let reserved = set.from_list(["read", "let", "and", "or", "not", "if"])
  let not_id_char = "[^a-zA-Z0-9_]"
  let not_eq_char = "[^=]"

  let l =
    lexer.simple([
      lexer.token("(", LParen),
      lexer.token(")", RParen),
      lexer.token("[", LBracket),
      lexer.token("]", RBracket),
      lexer.token("#t", Boolean(True)),
      lexer.token("#f", Boolean(False)),
      lexer.token("+", Keyword(Plus)),
      lexer.token("-", Keyword(Minus)),
      lexer.keyword(">", not_eq_char, Cmp(l_if.Gt)),
      lexer.keyword("<", not_eq_char, Cmp(l_if.Lt)),
      lexer.token(">=", Cmp(l_if.Gte)),
      lexer.token("<=", Cmp(l_if.Lte)),
      lexer.custom(lex_cmp_eq),
      // eq?
      lexer.keyword("read", not_id_char, Keyword(Read)),
      lexer.keyword("let", not_id_char, Keyword(Let)),
      lexer.keyword("and", not_id_char, Keyword(And)),
      lexer.keyword("or", not_id_char, Keyword(Or)),
      lexer.keyword("not", not_id_char, Keyword(Not)),
      lexer.keyword("if", not_id_char, Keyword(If)),
      lexer.int(Integer),
      lexer.variable(reserved, Identifier),
      lexer.ignore(lexer.whitespace(Nil)),
    ])

  lexer.run(input, l)
}

fn lex_cmp_eq(
  mode: Nil,
  lexeme: String,
  lookahead: String,
) -> lexer.Match(Token, Nil) {
  let is_prefix = string.starts_with("eq?", lexeme <> lookahead)
  case lexeme {
    "eq?" -> lexer.Keep(Cmp(l_if.Eq), mode)
    _ if is_prefix -> lexer.Skip
    _ -> lexer.NoMatch
  }
}

pub fn parse(
  tokens: List(lexer.Token(Token)),
) -> Result(l_if.Program, List(DeadEnd(Token, Nil))) {
  nibble.run(tokens, program())
}

fn program() -> Parser(l_if.Program, Token, Nil) {
  use body <- do(expression())
  return(l_if.Program(body:))
}

fn expression() -> Parser(l_if.Expr, Token, Nil) {
  nibble.one_of([integer(), boolean(), variable(), nested()])
}

fn nested() -> Parser(l_if.Expr, Token, Nil) {
  use _ <- do(nibble.token(LParen))
  use expr <- do(nibble.one_of([if_expr(), let_expr(), primitive()]))
  use _ <- do(nibble.token(RParen))
  return(expr)
}

fn if_expr() -> Parser(l_if.Expr, Token, Nil) {
  use _ <- do(nibble.token(Keyword(If)))
  use condition <- do(expression())
  use if_true <- do(expression())
  use if_false <- do(expression())

  return(l_if.If(condition:, if_true:, if_false:))
}

fn let_expr() -> Parser(l_if.Expr, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Let)))
  use _ <- do(nibble.token(LParen))
  use _ <- do(nibble.token(LBracket))
  use var <- do(identifier())
  use binding <- do(expression())
  use _ <- do(nibble.token(RBracket))
  use _ <- do(nibble.token(RParen))
  use expr <- do(expression())

  return(l_if.Let(var:, binding:, expr:))
}

fn primitive() -> Parser(l_if.Expr, Token, Nil) {
  use prim_op <- do(
    nibble.one_of([
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

  return(l_if.Prim(prim_op))
}

fn read_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Read)))
  return(l_if.Read)
}

fn minus_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Minus)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(l_if.Minus(arg1, arg2))
}

fn negate_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Minus)))
  use expr <- do(expression())

  return(l_if.Negate(expr))
}

fn plus_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Plus)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(l_if.Plus(arg1, arg2))
}

fn cmp_inner() -> Parser(l_if.Cmp, Token, Nil) {
  use tok <- nibble.take_map("expected comparison op")
  case tok {
    Cmp(op) -> Some(op)
    _ -> None
  }
}

fn cmp_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use op <- do(cmp_inner())
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(l_if.Cmp(op, arg1, arg2))
}

fn and_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(And)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(l_if.And(arg1, arg2))
}

fn or_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Or)))
  use arg1 <- do(expression())
  use arg2 <- do(expression())

  return(l_if.Or(arg1, arg2))
}

fn not_op() -> Parser(l_if.PrimOp, Token, Nil) {
  use _ <- do(nibble.token(Keyword(Not)))
  use expr <- do(expression())

  return(l_if.Not(expr))
}

fn boolean() -> Parser(l_if.Expr, Token, Nil) {
  use tok <- nibble.take_map("expected boolean")
  case tok {
    Boolean(b) -> Some(l_if.Bool(b))
    _ -> None
  }
}

fn integer() -> Parser(l_if.Expr, Token, Nil) {
  use tok <- nibble.take_map("expected integer")
  case tok {
    Integer(i) -> Some(l_if.Int(i))
    _ -> None
  }
}

fn variable() -> Parser(l_if.Expr, Token, Nil) {
  use id <- do(identifier())
  return(l_if.Var(id))
}

fn identifier() -> Parser(String, Token, Nil) {
  use tok <- nibble.take_map("expected identifier")
  case tok {
    Identifier(v) -> Some(v)
    _ -> None
  }
}
