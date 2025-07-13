import eoc/langs/l_if
import gleam/set
import gleam/string
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
