fn add(x : Int, y : Int) -> Int {
  x + y
}

pub fn hello() -> String {
  "hello".to_string()
}

struct Point {
  x : Int
  y : Int
}

pub struct Color {
  r : Byte
  g : Byte
  b : Byte
}

enum Shape {
  Circle(Double)
  Rect(Double, Double)
}

type Score = Int

fn compute() -> Int {
  let x = 1
  let y = 2
  x + y
}

fn counter() -> Int {
  let mut x = 0
  x = 10
  x
}

fn max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

const MAX_SIZE : Int = 100

fn swap(a : Int, b : Int) -> (Int, Int) {
  (b, a)
}

fn safe_div(a : Int, b : Int) -> Int? {
  if b == 0 {
    None
  } else {
    Some(a / b)
  }
}

fn sum_to(n : Int) -> Int {
  let mut total = 0
  let mut i = 1
  while i <= n {
    total = total + i
    i = i + 1
  }
  total
}

fn nums() -> Array[Int] {
  [1, 2, 3]
}

type Handle
