#![allow(dead_code, unused_variables, unused_mut, unreachable_code)]
use std::collections::HashMap;

fn add(x: i32, y: i32) -> i32 {
    x + y
}
pub fn hello() -> String {
    "hello".to_string()
}
struct Point {
    pub x: i32,
    pub y: i32,
}
pub struct Color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}
enum Shape {
    Circle(f64),
    Rect(f64, f64),
}
type Score = i32;
fn compute() -> i32 {
    let x = 1;
    let y = 2;
    x + y
}
fn counter() -> i32 {
    let mut x = 0;
    x = 10;
    x
}
fn max(a: i32, b: i32) -> i32 {
    if a > b {
        a
    } else {
        b
    }
}
const MAX_SIZE: i32 = 100;
fn swap(a: i32, b: i32) -> (i32, i32) {
    (b, a)
}
fn safe_div(a: i32, b: i32) -> Option<i32> {
    if b == 0 {
        None
    } else {
        Some(a / b)
    }
}
fn sum_to(n: i32) -> i32 {
    let mut total = 0;
    let mut i = 1;
    while i <= n {
        total = total + i;
        i = i + 1
    };
    total
}
fn nums() -> Vec<i32> {
    vec![1, 2, 3]
}
struct Handle;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(1, 2), 3);
    }

    #[test]
    fn test_max() {
        assert_eq!(max(3, 5), 5);
        assert_eq!(max(7, 2), 7);
    }

    #[test]
    fn test_swap() {
        assert_eq!(swap(1, 2), (2, 1));
    }

    #[test]
    fn test_compute() {
        assert_eq!(compute(), 3);
    }

    #[test]
    fn test_counter() {
        assert_eq!(counter(), 10);
    }

    #[test]
    fn test_sum_to() {
        assert_eq!(sum_to(10), 55);
    }

    #[test]
    fn test_safe_div() {
        assert_eq!(safe_div(10, 2), Some(5));
        assert_eq!(safe_div(10, 0), None);
    }

    #[test]
    fn test_struct() {
        let p = Point { x: 1, y: 2 };
        assert_eq!(p.x, 1);
        assert_eq!(p.y, 2);
    }

    #[test]
    fn test_nums() {
        assert_eq!(nums(), vec![1, 2, 3]);
    }
}
