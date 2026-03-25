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

///|
test "rust: for each" {
  assert_rust(
    (
      #|fn sum(arr : Array[Int]) -> Int {
      #|  let mut total = 0
      #|  for x in arr {
      #|    total = total + x
      #|  }
      #|  total
      #|}
    ),
    "fn sum(arr: Vec<i32>) -> i32 {\n    let mut total = 0;\n    for x in arr {\n        total = total + x\n    };\n    total\n}\n",
  )
}

///|
test "rust: closure" {
  assert_rust(
    (
      #|fn apply(f : (Int) -> Int, x : Int) -> Int { f(x) }
    ),
    "fn apply(f: fn(i32) -> i32, x: i32) -> i32 {\n    f(x)\n}\n",
  )
}

///|
test "rust: lambda" {
  assert_rust(
    (
      #|fn foo() -> Int {
      #|  let f = fn(x : Int) -> Int { x + 1 }
      #|  f(10)
      #|}
    ),
    "fn foo() -> i32 {\n    let f = |x: i32| -> i32 {\n        x + 1\n    };\n    f(10)\n}\n",
  )
}

///|
test "rust: record creation" {
  assert_rust(
    (
      #|struct Point { x : Int; y : Int }
      #|fn origin() -> Point { { x: 0, y: 0 } }
    ),
    "struct Point {\n    pub x: i32,\n    pub y: i32,\n}\nfn origin() -> Point {\n    { x: 0, y: 0 }\n}\n",
  )
}

///|
test "rust: field access" {
  assert_rust(
    (
      #|fn get_x(p : Point) -> Int { p.x }
    ),
    "fn get_x(p: Point) -> i32 {\n    p.x\n}\n",
  )
}

///|
test "rust: pattern match enum" {
  assert_rust(
    (
      #|fn area(s : Shape) -> Double {
      #|  match s {
      #|    Circle(r) => 3.14 * r * r
      #|    Rect(w, h) => w * h
      #|  }
      #|}
    ),
    "fn area(s: Shape) -> f64 {\n    match s {\n        Circle(r) => 3.14f64 * r * r,\n        Rect(w, h) => w * h,\n    }\n}\n",
  )
}

///|
test "rust: match with guard" {
  assert_rust(
    (
      #|fn classify(x : Int) -> String {
      #|  match x {
      #|    n if n > 0 => "positive"
      #|    n if n < 0 => "negative"
      #|    _ => "zero"
      #|  }
      #|}
    ),
    "fn classify(x: i32) -> String {\n    match x {\n        n if n > 0 => \"positive\",\n        n if n < 0 => \"negative\",\n        _ => \"zero\",\n    }\n}\n",
  )
}

///|
test "rust: tuple pattern" {
  assert_rust(
    (
      #|fn first(pair : (Int, Int)) -> Int {
      #|  let (a, _) = pair
      #|  a
      #|}
    ),
    "fn first(pair: (i32, i32)) -> i32 {\n    let (a, _) = pair;\n    a\n}\n",
  )
}

///|
test "rust: or pattern" {
  assert_rust(
    (
      #|fn is_weekend(day : Int) -> Bool {
      #|  match day {
      #|    6 | 7 => true
      #|    _ => false
      #|  }
      #|}
    ),
    "fn is_weekend(day: i32) -> bool {\n    match day {\n        6 | 7 => true,\n        _ => false,\n    }\n}\n",
  )
}

///|
test "rust: return early" {
  assert_rust(
    (
      #|fn check(x : Int) -> Int {
      #|  if x < 0 { return 0 }
      #|  x
      #|}
    ),
    "fn check(x: i32) -> i32 {\n    if x < 0 {\n        return 0\n    };\n    x\n}\n",
  )
}

///|
test "rust: nested function" {
  assert_rust(
    (
      #|fn outer() -> Int {
      #|  fn inner(x : Int) -> Int { x + 1 }
      #|  inner(10)
      #|}
    ),
    "fn outer() -> i32 {\n    let inner = |x: i32| -> i32 {\n        x + 1\n    };\n    inner(10)\n}\n",
  )
}

///|
test "rust: generic function" {
  assert_rust(
    (
      #|fn identity[T](x : T) -> T { x }
    ),
    "fn identity<T>(x: T) -> T {\n    x\n}\n",
  )
}

///|
test "rust: tuple struct" {
  assert_rust(
    (
      #|struct Wrapper(Int)
    ),
    "struct Wrapper(i32);\n",
  )
}

///|
test "rust: unary op" {
  assert_rust(
    (
      #|fn negate(x : Int) -> Int { -x }
    ),
    "fn negate(x: i32) -> i32 {\n    -x\n}\n",
  )
}

///|
test "rust: logical not" {
  assert_rust(
    (
      #|fn invert(b : Bool) -> Bool { not(b) }
    ),
    "fn invert(b: bool) -> bool {\n    not(b)\n}\n",
  )
}

///|
test "rust: chained method calls" {
  assert_rust(
    (
      #|fn process(s : String) -> Int { s.trim().length() }
    ),
    "fn process(s: String) -> i32 {\n    s.trim().length()\n}\n",
  )
}

///|
test "rust: multiple statements" {
  assert_rust(
    (
      #|fn multi() -> Int {
      #|  let a = 1
      #|  let b = 2
      #|  let c = 3
      #|  a + b + c
      #|}
    ),
    "fn multi() -> i32 {\n    let a = 1;\n    let b = 2;\n    let c = 3;\n    a + b + c\n}\n",
  )
}

///|
test "rust: match with constructor and args" {
  assert_rust(
    (
      #|fn unwrap_or(opt : Int?, default : Int) -> Int {
      #|  match opt {
      #|    Some(v) => v
      #|    None => default
      #|  }
      #|}
    ),
    "fn unwrap_or(opt: Option<i32>, default: i32) -> i32 {\n    match opt {\n        Some(v) => v,\n        None => default,\n    }\n}\n",
  )
}

///|
test "rust: hole/todo" {
  assert_rust(
    (
      #|fn placeholder() -> Int { _ }
    ),
    "fn placeholder() -> i32 {\n    todo!(\"...\")\n}\n",
  )
}

///|
test "rust: nested if" {
  assert_rust(
    (
      #|fn clamp(x : Int, lo : Int, hi : Int) -> Int {
      #|  if x < lo { lo } else { if x > hi { hi } else { x } }
      #|}
    ),
    "fn clamp(x: i32, lo: i32, hi: i32) -> i32 {\n    if x < lo {\n        lo\n    } else {\n        if x > hi {\n            hi\n        } else {\n            x\n        }\n    }\n}\n",
  )
}

///|
test "rust: let with type annotation" {
  assert_rust(
    (
      #|fn typed() -> Int {
      #|  let x : Int = 42
      #|  x
      #|}
    ),
    "fn typed() -> i32 {\n    let x: i32 = 42;\n    x\n}\n",
  )
}

///|
test "rust: array index set" {
  assert_rust(
    (
      #|fn set_first(arr : Array[Int]) -> Unit {
      #|  arr[0] = 99
      #|}
    ),
    "fn set_first(arr: Vec<i32>) {\n    arr[0] = 99\n}\n",
  )
}
