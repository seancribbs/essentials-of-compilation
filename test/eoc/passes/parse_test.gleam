import eoc/langs/l_fun.{Eq, Gt, Gte, Lt, Lte} as l
import eoc/passes/parse.{
  type Token, And, Arrow, Boolean, Cmp, Colon, Define, Identifier, If, Integer,
  Keyword, LBracket, LParen, Let, Minus, Not, Or, Plus, RBracket, RParen, Read,
  TypeName, parse, tokens,
}
import gleam/list

fn tokenized(input: String) -> List(Token) {
  let assert Ok(value) = tokens(input)
  value
  |> list.map(fn(tok) { tok.value })
}

pub fn tokens_test() {
  // Integers
  assert tokenized("1 2 3 9223372036854775807 18446744073709551616 42")
    == [
      Integer(1),
      Integer(2),
      Integer(3),
      Integer(9_223_372_036_854_775_807),
      Integer(18_446_744_073_709_551_616),
      Integer(42),
    ]
  // Punctuation
  assert tokenized(" ( ) [ ] : ->")
    == [LParen, RParen, LBracket, RBracket, Colon, Arrow]
  // Keywords
  assert tokenized("#t #f") == [Boolean(True), Boolean(False)]
  assert tokenized("read let + - and or not if")
    == [
      Keyword(Read),
      Keyword(Let),
      Keyword(Plus),
      Keyword(Minus),
      Keyword(And),
      Keyword(Or),
      Keyword(Not),
      Keyword(If),
    ]
  // Comparison ops
  assert tokenized("eq?") == [Cmp(Eq)]
  assert tokenized("> < >= <=") == [Cmp(Gt), Cmp(Lt), Cmp(Gte), Cmp(Lte)]

  // Identifiers
  assert tokenized("a b c something var1234 var_3")
    == [
      Identifier("a"),
      Identifier("b"),
      Identifier("c"),
      Identifier("something"),
      Identifier("var1234"),
      Identifier("var_3"),
    ]

  // Realistic example
  assert tokenized(
      " (define (inc [ x : Integer ]) : Integer (+ x 1))

    (let ([y (if #t
              (read)
              (if (eq? (read) 0)
                  777
                  (let ([x (read)]) (+ 1 x))))])
    (+ y 2))",
    )
    == [
      LParen,
      Keyword(Define),
      LParen,
      Identifier("inc"),
      LBracket,
      Identifier("x"),
      Colon,
      TypeName("Integer"),
      RBracket,
      RParen,
      Colon,
      TypeName("Integer"),
      LParen,
      Keyword(Plus),
      Identifier("x"),
      Integer(1),
      RParen,
      RParen,
      LParen,
      Keyword(Let),
      LParen,
      LBracket,
      Identifier("y"),
      LParen,
      Keyword(If),
      Boolean(True),
      LParen,
      Keyword(Read),
      RParen,
      LParen,
      Keyword(If),
      LParen,
      Cmp(Eq),
      LParen,
      Keyword(Read),
      RParen,
      Integer(0),
      RParen,
      Integer(777),
      LParen,
      Keyword(Let),
      LParen,
      LBracket,
      Identifier("x"),
      LParen,
      Keyword(Read),
      RParen,
      RBracket,
      RParen,
      LParen,
      Keyword(Plus),
      Integer(1),
      Identifier("x"),
      RParen,
      RParen,
      RParen,
      RParen,
      RBracket,
      RParen,
      LParen,
      Keyword(Plus),
      Identifier("y"),
      Integer(2),
      RParen,
      RParen,
    ]
}

pub fn parse_test() {
  let p =
    l.ProgramDefsExp(
      [],
      l.Let(
        "y",
        l.If(
          l.Bool(True),
          l.Prim(l.Read),
          l.If(
            l.Prim(l.Cmp(l.Eq, l.Prim(l.Read), l.Int(0))),
            l.Int(777),
            l.Let("x", l.Prim(l.Read), l.Prim(l.Plus(l.Int(1), l.Var("x")))),
          ),
        ),
        l.Prim(l.Plus(l.Var("y"), l.Int(2))),
      ),
    )

  let assert Ok(toks) =
    tokens(
      "(let ([y (if #t
              (read)
              (if (eq? (read) 0)
                  777
                  (let ([x (read)]) (+ 1 x))))])
    (+ y 2))",
    )
  let assert Ok(value) = parse(toks)
  assert value == p
}

pub fn parse_while_test() {
  let p =
    l.ProgramDefsExp(
      [],
      l.Let(
        "sum",
        l.Int(0),
        l.Let(
          "i",
          l.Int(5),
          l.Begin(
            [
              l.WhileLoop(
                l.Prim(l.Cmp(Gt, l.Var("i"), l.Int(0))),
                l.Begin(
                  [l.SetBang("sum", l.Prim(l.Plus(l.Var("sum"), l.Var("i"))))],
                  l.SetBang("i", l.Prim(l.Minus(l.Var("i"), l.Int(1)))),
                ),
              ),
            ],
            l.Var("sum"),
          ),
        ),
      ),
    )

  let assert Ok(toks) =
    tokens(
      "(let ([sum 0])
    (let ([i 5])
      (begin
        (while (> i 0)
          (begin
            (set! sum (+ sum i))
            (set! i (- i 1))))
        sum)))",
    )

  let assert Ok(value) = parse(toks)
  assert value == p
}

pub fn parse_defs_test() {
  let assert Ok(toks) =
    tokens(
      "(define (map [f : (Integer -> Integer)] [v : (Vector Integer Integer)]) : (Vector Integer Integer)
    (vector (f (vector-ref v 0)) (f (vector-ref v 1))))

  (define (inc [x : Integer]) : Integer
    (+ x 1))

    (vector-ref (map inc (vector 0 41)) 1)",
    )

  let assert Ok(_) = parse(toks)
}
