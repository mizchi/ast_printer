///|
/// Helper: parse MoonBit source and convert to Rust.
fn assert_rust(source : String, expected : String) -> Unit raise {
  let (impls, errors) = @moonbitlang/parser.parse_string(source)
  assert_eq(errors.length(), 0)
  let result = to_rust(impls)
  assert_eq(result, expected)
}

///|
test "rust: simple function" {
  assert_rust(
    (
      #|fn add(x : Int, y : Int) -> Int { x + y }
    ),
    "fn add(x: i32, y: i32) -> i32 {\n    x + y\n}\n",
  )
}

///|
test "rust: pub function" {
  assert_rust(
    (
      #|pub fn hello() -> String { "hello" }
    ),
    "pub fn hello() -> String {\n    \"hello\"\n}\n",
  )
}

///|
test "rust: struct" {
  assert_rust(
    (
      #|struct Point { x : Int; y : Int }
    ),
    "struct Point {\n    pub x: i32,\n    pub y: i32,\n}\n",
  )
}

///|
test "rust: pub struct" {
  assert_rust(
    (
      #|pub struct Point { x : Int; y : Int }
    ),
    "pub struct Point {\n    pub x: i32,\n    pub y: i32,\n}\n",
  )
}

///|
test "rust: enum" {
  assert_rust(
    (
      #|enum Color { Red; Green; Blue }
    ),
    "enum Color {\n    Red,\n    Green,\n    Blue,\n}\n",
  )
}

///|
test "rust: enum with payload" {
  assert_rust(
    (
      #|enum Shape { Circle(Double); Rect(Double, Double) }
    ),
    "enum Shape {\n    Circle(f64),\n    Rect(f64, f64),\n}\n",
  )
}

///|
test "rust: type alias" {
  assert_rust(
    (
      #|type Point = Int
    ),
    "type Point = i32;\n",
  )
}

///|
test "rust: generic type" {
  assert_rust(
    (
      #|fn first(arr : Array[Int]) -> Int { arr[0] }
    ),
    "fn first(arr: Vec<i32>) -> i32 {\n    arr[0]\n}\n",
  )
}

///|
test "rust: let binding" {
  assert_rust(
    (
      #|fn foo() -> Int {
      #|  let x = 1
      #|  x
      #|}
    ),
    "fn foo() -> i32 {\n    let x = 1;\n    x\n}\n",
  )
}

///|
test "rust: let mut" {
  assert_rust(
    (
      #|fn foo() -> Int {
      #|  let mut x = 0
      #|  x = 1
      #|  x
      #|}
    ),
    "fn foo() -> i32 {\n    let mut x = 0;\n    x = 1;\n    x\n}\n",
  )
}

///|
test "rust: if else" {
  assert_rust(
    (
      #|fn abs(x : Int) -> Int {
      #|  if x >= 0 { x } else { 0 - x }
      #|}
    ),
    "fn abs(x: i32) -> i32 {\n    if x >= 0 {\n        x\n    } else {\n        0 - x\n    }\n}\n",
  )
}

///|
test "rust: match" {
  assert_rust(
    (
      #|fn describe(x : Int) -> String {
      #|  match x {
      #|    0 => "zero"
      #|    _ => "other"
      #|  }
      #|}
    ),
    "fn describe(x: i32) -> String {\n    match x {\n        0 => \"zero\",\n        _ => \"other\",\n    }\n}\n",
  )
}

///|
test "rust: const" {
  assert_rust(
    (
      #|const PI : Double = 3.14159
    ),
    "const PI: f64 = 3.14159f64;\n",
  )
}

///|
test "rust: tuple" {
  assert_rust(
    (
      #|fn pair() -> (Int, String) { (1, "hello") }
    ),
    "fn pair() -> (i32, String) {\n    (1, \"hello\")\n}\n",
  )
}

///|
test "rust: pipe operator desugaring" {
  assert_rust(
    (
      #|fn foo(x : Int) -> Int { x |> bar }
    ),
    "fn foo(x: i32) -> i32 {\n    bar(x)\n}\n",
  )
}

///|
// TODO: string interpolation needs investigation on how parser represents \{expr}
// test "rust: string interpolation" {
//   let source = "fn greet(name : String) -> String { \"hello \\{name}\" }"
//   assert_rust(
//     source,
//     "fn greet(name: String) -> String {\n    format!(\"hello {}\", name)\n}\n",
//   )
// }

///|
test "rust: option type" {
  assert_rust(
    (
      #|fn find(x : Int) -> Int? { None }
    ),
    "fn find(x: i32) -> Option<i32> {\n    None\n}\n",
  )
}

///|
test "rust: method call" {
  assert_rust(
    (
      #|fn len(s : String) -> Int { s.length() }
    ),
    "fn len(s: String) -> i32 {\n    s.length()\n}\n",
  )
}

///|
test "rust: while loop" {
  assert_rust(
    (
      #|fn count() -> Unit {
      #|  let mut i = 0
      #|  while i < 10 {
      #|    i = i + 1
      #|  }
      #|}
    ),
    "fn count() {\n    let mut i = 0;\n    while i < 10 {\n        i = i + 1\n    }\n}\n",
  )
}

///|
test "rust: array literal" {
  assert_rust(
    (
      #|fn nums() -> Array[Int] { [1, 2, 3] }
    ),
    "fn nums() -> Vec<i32> {\n    vec![1, 2, 3]\n}\n",
  )
}

///|
test "rust: is expression" {
  assert_rust(
    (
      #|fn is_some(x : Int?) -> Bool { x is Some(_) }
    ),
    "fn is_some(x: Option<i32>) -> bool {\n    matches!(x, Some(_))\n}\n",
  )
}

///|
test "rust: trait" {
  assert_rust(
    (
      #|trait Printable { to_string(Self) -> String }
    ),
    "trait Printable {\n    fn to_string(&self) -> String;\n}\n",
  )
}
