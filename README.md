# ast_printer

MoonBit AST to source code printer.

## Installation

```bash
moon add mizchi/ast_printer
```

## Usage

```moonbit
import { parse_string } from "moonbitlang/parser"
import { print_code, print_impls } from "mizchi/ast_printer"

fn main {
  let source = "fn add(a : Int, b : Int) -> Int { a + b }"

  // Option 1: Use print_code (returns None on parse error)
  match print_code(parse_string(source)) {
    Some(code) => println(code)
    None => println("Parse error")
  }

  // Option 2: Use print_impls directly
  let (impls, errors) = parse_string(source)
  if errors.length() == 0 {
    println(print_impls(impls))
  }
}
```

## Features

- Complete coverage of top-level declarations (functions, structs, enums, traits, impl blocks, type aliases, etc.)
- Expression printing with proper operator precedence
- Pattern and type printing
- Tab-based indentation for nested structures
- Round-trip tested: `parse → print → parse → print` produces identical output

## API

### `print_code(parsed: (Impls, Array[Report])) -> String?`

Convenience function that takes `parse_string` result directly.
Returns `None` if there are parse errors.

### `print_impls(impls: Impls) -> String`

Print a list of top-level implementations to a string.

## License

MIT
