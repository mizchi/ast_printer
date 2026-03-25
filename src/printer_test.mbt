///|
/// Round-trip test helper: parse → print → parse → print
/// The two print results should be identical.
fn assert_roundtrip(source : String) -> Unit raise {
  let (impls1, errors1) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors1.length(), 0)
  let printed1 = print_impls(impls1)
  let (impls2, errors2) = @moonbitlang/parser.parse_string(printed1)
  assert_eq(errors2.length(), 0)
  let printed2 = print_impls(impls2)
  assert_eq(printed1, printed2)
}

///|
test "print_code with valid source" {
  let source =
    #|fn hello() -> String {
    #|  "hello"
    #|}
  let result = print_code(@moonbitlang/parser.parse_string(source))
  assert_true(result is Some(_))
}

///|
test "print_code with parse error" {
  let source = "fn invalid { {"
  let result = print_code(@moonbitlang/parser.parse_string(source))
  assert_true(result is None)
}

///|
test "print simple function" {
  let source =
    #|fn add(a : Int, b : Int) -> Int {
    #|  a + b
    #|}
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(result, content="fn add(a : Int, b : Int) -> Int {\n\ta + b\n}\n")
}

///|
test "print struct" {
  let source =
    #|struct Point {
    #|  x : Int
    #|  y : Int
    #|}
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(result, content="struct Point {\n  x : Int\n  y : Int\n}\n")
}

///|
test "print enum" {
  let source =
    #|enum Color {
    #|  Red
    #|  Green
    #|  Blue
    #|}
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(result, content="enum Color {\n  Red\n  Green\n  Blue\n}\n")
}

///|
test "print let binding" {
  let source =
    #|let x : Int = 42
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(result, content="let x : Int = 42\n")
}

///|
test "print match expression" {
  let source =
    #|fn describe(n : Int) -> String {
    #|  match n {
    #|    0 => "zero"
    #|    _ => "other"
    #|  }
    #|}
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(
    result,
    content="fn describe(n : Int) -> String {\n\tmatch n {\n\t\t0 => \"zero\"\n\t\t_ => \"other\"\n\t}\n}\n",
  )
}

///|
test "print operator precedence" {
  let source =
    #|fn calc() -> Int {
    #|  1 + 2 * 3
    #|}
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(result, content="fn calc() -> Int {\n\t1 + 2 * 3\n}\n")
}

///|
test "print deprecated attribute" {
  let source =
    #|#deprecated("Use bar instead")
    #|fn foo() -> Unit {
    #|  ()
    #|}
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(
    result,
    content="#deprecated(\"Use bar instead\")\nfn foo() -> Unit {\n\t()\n}\n",
  )
}

///|
test "print doc comment" {
  let source =
    #|/// This is a doc comment.
    #|fn documented() -> Unit {
    #|  ()
    #|}
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = print_impls(impls)
  inspect(
    result,
    content="/// This is a doc comment.\nfn documented() -> Unit {\n\t()\n}\n",
  )
}

///|
test "roundtrip: simple function" {
  assert_roundtrip(
    (
      #|fn add(a : Int, b : Int) -> Int {
      #|  a + b
      #|}
    ),
  )
}

///|
test "roundtrip: struct" {
  assert_roundtrip(
    (
      #|struct Point {
      #|  x : Int
      #|  y : Int
      #|}
    ),
  )
}

///|
test "roundtrip: enum" {
  assert_roundtrip(
    (
      #|enum Color {
      #|  Red
      #|  Green
      #|  Blue(Int)
      #|}
    ),
  )
}

///|
test "roundtrip: match expression" {
  assert_roundtrip(
    (
      #|fn describe(n : Int) -> String {
      #|  match n {
      #|    0 => "zero"
      #|    1 | 2 => "small"
      #|    _ => "other"
      #|  }
      #|}
    ),
  )
}

///|
test "roundtrip: if expression" {
  assert_roundtrip(
    (
      #|fn max(a : Int, b : Int) -> Int {
      #|  if a > b { a } else { b }
      #|}
    ),
  )
}

///|
test "roundtrip: while loop" {
  assert_roundtrip(
    (
      #|fn count() -> Unit {
      #|  let mut i = 0
      #|  while i < 10 {
      #|    i = i + 1
      #|  }
      #|}
    ),
  )
}

///|
test "roundtrip: for loop" {
  assert_roundtrip(
    (
      #|fn sum(arr : Array[Int]) -> Int {
      #|  let mut total = 0
      #|  for i in arr {
      #|    total = total + i
      #|  }
      #|  total
      #|}
    ),
  )
}

///|
test "roundtrip: trait" {
  assert_roundtrip(
    (
      #|trait Show {
      #|  show(Self) -> String
      #|}
    ),
  )
}

///|
test "roundtrip: method call" {
  assert_roundtrip(
    (
      #|fn process(s : String) -> Int {
      #|  s.length()
      #|}
    ),
  )
}

///|
test "roundtrip: array and tuple" {
  assert_roundtrip(
    (
      #|fn make_pair() -> (Int, String) {
      #|  (1, "hello")
      #|}
    ),
  )
}

///|
test "roundtrip: record pattern" {
  assert_roundtrip(
    (
      #|fn get_x(p : Point) -> Int {
      #|  match p {
      #|    { x, .. } => x
      #|  }
      #|}
    ),
  )
}

///|
test "roundtrip: generic function" {
  assert_roundtrip(
    (
      #|fn identity[T](x : T) -> T {
      #|  x
      #|}
    ),
  )
}

///|
test "roundtrip: impl trait" {
  assert_roundtrip(
    (
      #|impl Show for Point with output(self, logger) {
      #|  logger.write_string("Point")
      #|}
    ),
  )
}

///|
test "roundtrip: type alias" {
  assert_roundtrip(
    (
      #|type Point = Int
    ),
  )
}

///|
test "roundtrip: attribute" {
  assert_roundtrip(
    (
      #|#deprecated("Use bar instead")
      #|fn foo() -> Unit {
      #|  ()
      #|}
    ),
  )
}

///|
test "roundtrip: lambda" {
  assert_roundtrip(
    (
      #|fn apply(f : (Int) -> Int, x : Int) -> Int {
      #|  f(x)
      #|}
    ),
  )
}

///|
test "roundtrip: array literal" {
  assert_roundtrip(
    (
      #|fn make_array() -> Array[Int] {
      #|  [1, 2, 3]
      #|}
    ),
  )
}

///|
test "roundtrip: labeled arguments" {
  assert_roundtrip(
    (
      #|fn greet(name~ : String, age~ : Int) -> String {
      #|  name
      #|}
    ),
  )
}

///|
test "roundtrip: optional arguments" {
  assert_roundtrip(
    (
      #|fn greet(name~ : String = "world") -> String {
      #|  name
      #|}
    ),
  )
}

///|
test "roundtrip: pipe operator" {
  assert_roundtrip(
    (
      #|fn process(x : Int) -> Int {
      #|  x |> add1 |> double
      #|}
    ),
  )
}

///|
test "roundtrip: try catch" {
  assert_roundtrip(
    (
      #|fn safe_div(a : Int, b : Int) -> Int {
      #|  try {
      #|    a / b
      #|  } catch {
      #|    _ => 0
      #|  }
      #|}
    ),
  )
}

///|
test "roundtrip: guard" {
  assert_roundtrip(
    (
      #|fn check(x : Int) -> String {
      #|  match x {
      #|    n if n > 0 => "positive"
      #|    _ => "non-positive"
      #|  }
      #|}
    ),
  )
}

///|
test "roundtrip: loop break continue" {
  assert_roundtrip(
    (
      #|fn find_first(arr : Array[Int]) -> Int {
      #|  loop arr {
      #|    [] => break 0
      #|    [x, .. rest] => if x > 0 { break x } else { continue rest }
      #|  }
      #|}
    ),
  )
}

///|
test "roundtrip: newtype" {
  assert_roundtrip(
    (
      #|type UserId = Int
    ),
  )
}

///|
test "roundtrip: const" {
  assert_roundtrip(
    (
      #|const PI : Double = 3.14159
    ),
  )
}

///|
test "roundtrip: pub function" {
  assert_roundtrip(
    (
      #|pub fn public_fn() -> Unit {
      #|  ()
      #|}
    ),
  )
}

///|
test "roundtrip: priv function" {
  assert_roundtrip(
    (
      #|priv fn private_fn() -> Unit {
      #|  ()
      #|}
    ),
  )
}

///|
test "roundtrip: struct with mut field" {
  assert_roundtrip(
    (
      #|struct Counter {
      #|  mut count : Int
      #|}
    ),
  )
}

///|
test "roundtrip: enum with multiple fields" {
  assert_roundtrip(
    (
      #|enum Shape {
      #|  Circle(Double)
      #|  Rectangle(Double, Double)
      #|  Point
      #|}
    ),
  )
}

///|
test "roundtrip: trait with multiple methods" {
  assert_roundtrip(
    (
      #|trait Comparable {
      #|  compare(Self, Self) -> Int
      #|  equal(Self, Self) -> Bool
      #|}
    ),
  )
}

///|
test "roundtrip: generic struct" {
  assert_roundtrip(
    (
      #|struct Pair[A, B] {
      #|  first : A
      #|  second : B
      #|}
    ),
  )
}

///|
test "roundtrip: constraint" {
  assert_roundtrip(
    (
      #|fn print_all[T : Show](items : Array[T]) -> Unit {
      #|  ()
      #|}
    ),
  )
}

///|
test "roundtrip: nested match" {
  assert_roundtrip(
    (
      #|fn nested(x : Option[Option[Int]]) -> Int {
      #|  match x {
      #|    Some(Some(n)) => n
      #|    Some(None) => 0
      #|    None => -1
      #|  }
      #|}
    ),
  )
}

///|
test "roundtrip: string interpolation" {
  assert_roundtrip(
    (
      #|fn greet(name : String) -> String {
      #|  "Hello, \{name}!"
      #|}
    ),
  )
}

///|
test "roundtrip: range" {
  assert_roundtrip(
    (
      #|fn sum_range() -> Int {
      #|  let mut sum = 0
      #|  for i in 0..<10 {
      #|    sum = sum + i
      #|  }
      #|  sum
      #|}
    ),
  )
}

///|
test "roundtrip: method chain" {
  assert_roundtrip(
    (
      #|fn process(s : String) -> String {
      #|  s.trim().to_upper()
      #|}
    ),
  )
}

///|
test "roundtrip: binary operators" {
  assert_roundtrip(
    (
      #|fn ops(a : Int, b : Int) -> Bool {
      #|  a + b > 0 && a - b < 10 || a * b == 0
      #|}
    ),
  )
}

///|
test "roundtrip: unary operators" {
  assert_roundtrip(
    (
      #|fn neg(x : Int, b : Bool) -> (Int, Bool) {
      #|  (-x, not(b))
      #|}
    ),
  )
}

///|
test "roundtrip: record literal" {
  assert_roundtrip(
    (
      #|fn make_point(x : Int, y : Int) -> Point {
      #|  { x, y }
      #|}
    ),
  )
}

///|
test "roundtrip: record update" {
  assert_roundtrip(
    (
      #|fn move_x(p : Point, dx : Int) -> Point {
      #|  { ..p, x: p.x + dx }
      #|}
    ),
  )
}

///|
test "roundtrip: as pattern" {
  assert_roundtrip(
    (
      #|fn first_or_all(arr : Array[Int]) -> Array[Int] {
      #|  match arr {
      #|    [x, ..] as all => all
      #|    [] => []
      #|  }
      #|}
    ),
  )
}
