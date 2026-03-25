///|
/// Print an expression as Rust.
pub fn rust_print_expr(
  buf : StringBuilder,
  expr : @syntax.Expr,
  indent? : Int = 0,
) -> Unit {
  match expr {
    // Literals
    Constant(c~, ..) => rust_print_constant(buf, c)
    Unit(..) => buf.write_string("()")

    // Identifiers
    Ident(id~, ..) => rust_print_var(buf, id)
    Constr(constr~, ..) => rust_print_constructor(buf, constr)

    // Collections
    Array(exprs~, ..) => {
      buf.write_string("vec![")
      let mut first = true
      for e in exprs {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        rust_print_expr(buf, e)
      }
      buf.write_char(']')
    }
    ArraySpread(elems~, ..) => {
      buf.write_string("vec![")
      let mut first = true
      for e in elems {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        match e {
          Regular(expr) => rust_print_expr(buf, expr)
          Spread(..) => rust_todo(buf, "array spread")
        }
      }
      buf.write_char(']')
    }
    Tuple(exprs~, ..) => {
      buf.write_char('(')
      let mut first = true
      for e in exprs {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        rust_print_expr(buf, e)
      }
      buf.write_char(')')
    }

    // Function application
    Apply(func~, args~, attr~, ..) => {
      rust_print_expr(buf, func)
      buf.write_char('(')
      rust_print_arguments(buf, args)
      buf.write_char(')')
      match attr {
        NoAttr => ()
        Exclamation => buf.write_string(" /* ! */")
        Question => buf.write_char('?')
      }
    }

    // Operators
    Infix(op~, lhs~, rhs~, ..) => {
      rust_print_expr(buf, lhs, indent~)
      buf.write_char(' ')
      rust_print_var(buf, op)
      buf.write_char(' ')
      rust_print_expr(buf, rhs, indent~)
    }
    Unary(op~, expr~, ..) => {
      rust_print_var(buf, op)
      rust_print_expr(buf, expr)
    }
    Pipe(lhs~, rhs~, ..) => {
      // Desugar pipe: lhs |> rhs  =>  rhs(lhs)
      rust_print_expr(buf, rhs)
      buf.write_char('(')
      rust_print_expr(buf, lhs)
      buf.write_char(')')
    }

    // Array operations
    ArrayGet(array~, index~, ..) => {
      rust_print_expr(buf, array)
      buf.write_char('[')
      rust_print_expr(buf, index)
      buf.write_char(']')
    }
    ArrayGetSlice(array~, start_index~, end_index~, ..) => {
      rust_print_expr(buf, array)
      buf.write_char('[')
      match start_index {
        Some(e) => rust_print_expr(buf, e)
        None => ()
      }
      buf.write_string("..")
      match end_index {
        Some(e) => rust_print_expr(buf, e)
        None => ()
      }
      buf.write_char(']')
    }
    ArraySet(array~, index~, value~, ..) => {
      rust_print_expr(buf, array)
      buf.write_char('[')
      rust_print_expr(buf, index)
      buf.write_string("] = ")
      rust_print_expr(buf, value)
    }
    ArrayAugmentedSet(op~, array~, index~, value~, ..) => {
      rust_print_expr(buf, array)
      buf.write_char('[')
      rust_print_expr(buf, index)
      buf.write_string("] ")
      rust_print_var(buf, op)
      buf.write_string("= ")
      rust_print_expr(buf, value)
    }

    // Control flow
    If(cond~, ifso~, ifnot~, ..) => {
      buf.write_string("if ")
      rust_print_expr(buf, cond)
      buf.write_string(" {\n")
      rust_print_indent(buf, indent + 1)
      rust_print_expr(buf, ifso, indent=indent + 1)
      buf.write_char('\n')
      rust_print_indent(buf, indent)
      buf.write_char('}')
      match ifnot {
        Some(e) => {
          buf.write_string(" else {\n")
          rust_print_indent(buf, indent + 1)
          rust_print_expr(buf, e, indent=indent + 1)
          buf.write_char('\n')
          rust_print_indent(buf, indent)
          buf.write_char('}')
        }
        None => ()
      }
    }
    Match(expr~, cases~, ..) => {
      buf.write_string("match ")
      rust_print_expr(buf, expr, indent~)
      buf.write_string(" {\n")
      for c in cases {
        rust_print_indent(buf, indent + 1)
        rust_print_pattern(buf, c.pattern)
        match c.guard_ {
          Some(g) => {
            buf.write_string(" if ")
            rust_print_expr(buf, g, indent~)
          }
          None => ()
        }
        buf.write_string(" => ")
        rust_print_expr(buf, c.body, indent=indent + 1)
        buf.write_string(",\n")
      }
      rust_print_indent(buf, indent)
      buf.write_char('}')
    }
    While(loop_cond~, loop_body~, label~, ..) => {
      ignore(label)
      buf.write_string("while ")
      rust_print_expr(buf, loop_cond, indent~)
      buf.write_string(" {\n")
      rust_print_indent(buf, indent + 1)
      rust_print_expr(buf, loop_body, indent=indent + 1)
      buf.write_char('\n')
      rust_print_indent(buf, indent)
      buf.write_char('}')
    }
    ForEach(binders~, expr~, body~, label~, ..) => {
      ignore(label)
      buf.write_string("for ")
      let mut first = true
      for b in binders {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        match b {
          Some(binder) => buf.write_string(binder.name)
          None => buf.write_char('_')
        }
      }
      buf.write_string(" in ")
      rust_print_expr(buf, expr, indent~)
      buf.write_string(" {\n")
      rust_print_indent(buf, indent + 1)
      rust_print_expr(buf, body, indent=indent + 1)
      buf.write_char('\n')
      rust_print_indent(buf, indent)
      buf.write_char('}')
    }
    For(..) => rust_todo(buf, "C-style for loop")
    Loop(..) => rust_todo(buf, "functional loop")

    // Functions / closures
    Function(func~, ..) => {
      buf.write_string("|")
      rust_print_closure_params(buf, func.parameters)
      buf.write_string("| ")
      match func.return_type {
        Some(t) => {
          buf.write_string("-> ")
          rust_print_type(buf, t)
          buf.write_char(' ')
        }
        None => ()
      }
      buf.write_string("{\n")
      rust_print_indent(buf, indent + 1)
      rust_print_expr(buf, func.body, indent=indent + 1)
      buf.write_char('\n')
      rust_print_indent(buf, indent)
      buf.write_char('}')
    }

    // Let bindings
    Let(pattern~, expr~, body~, ..) => {
      buf.write_string("let ")
      rust_print_pattern(buf, pattern)
      buf.write_string(" = ")
      rust_print_expr(buf, expr, indent~)
      buf.write_string(";\n")
      rust_print_indent(buf, indent)
      rust_print_expr(buf, body, indent~)
    }
    LetMut(binder~, ty~, expr~, body~, ..) => {
      buf.write_string("let mut ")
      buf.write_string(binder.name)
      match ty {
        Some(t) => {
          buf.write_string(": ")
          rust_print_type(buf, t)
        }
        None => ()
      }
      buf.write_string(" = ")
      rust_print_expr(buf, expr)
      buf.write_string(";\n")
      rust_print_indent(buf, indent)
      rust_print_expr(buf, body, indent~)
    }
    LetFn(name~, func~, body~, ..) => {
      buf.write_string("let ")
      buf.write_string(name.name)
      buf.write_string(" = |")
      rust_print_closure_params(buf, func.parameters)
      buf.write_string("| ")
      buf.write_string("{\n")
      rust_print_indent(buf, indent + 1)
      rust_print_expr(buf, func.body, indent=indent + 1)
      buf.write_char('\n')
      rust_print_indent(buf, indent)
      buf.write_string("};\n")
      rust_print_indent(buf, indent)
      rust_print_expr(buf, body, indent~)
    }
    LetRec(..) => rust_todo(buf, "let rec")
    LetAnd(..) => rust_todo(buf, "let and")

    // Sequences
    Sequence(exprs~, last_expr~, ..) => {
      for e in exprs {
        rust_print_expr(buf, e, indent~)
        buf.write_string(";\n")
        rust_print_indent(buf, indent)
      }
      rust_print_expr(buf, last_expr, indent~)
    }

    // Records
    Record(type_name~, fields~, ..) => {
      match type_name {
        Some(tn) => {
          rust_print_type_name(buf, tn)
          buf.write_char(' ')
        }
        None => ()
      }
      buf.write_string("{ ")
      let mut first = true
      for f in fields {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        if f.is_pun {
          buf.write_string(f.label.name)
        } else {
          buf.write_string(f.label.name)
          buf.write_string(": ")
          rust_print_expr(buf, f.expr)
        }
      }
      buf.write_string(" }")
    }
    RecordUpdate(type_name~, record~, fields~, ..) => {
      match type_name {
        Some(tn) => {
          rust_print_type_name(buf, tn)
          buf.write_char(' ')
        }
        None => ()
      }
      buf.write_string("{ ")
      let mut first = true
      for f in fields {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        if f.is_pun {
          buf.write_string(f.label.name)
        } else {
          buf.write_string(f.label.name)
          buf.write_string(": ")
          rust_print_expr(buf, f.expr)
        }
      }
      buf.write_string(", ..")
      rust_print_expr(buf, record)
      buf.write_string(" }")
    }
    Field(record~, accessor~, ..) => {
      rust_print_expr(buf, record)
      buf.write_char('.')
      match accessor {
        Label(label) => buf.write_string(label.name)
        Index(tuple_index~, ..) => buf.write_string(tuple_index.to_string())
        Newtype(..) => buf.write_string("0") // newtype field access -> .0
      }
    }
    Method(type_name~, method_name~, ..) => {
      rust_print_type_name(buf, type_name)
      buf.write_string("::")
      buf.write_string(method_name.name)
    }
    DotApply(self~, method_name~, args~, attr~, ..) => {
      rust_print_expr(buf, self)
      buf.write_char('.')
      buf.write_string(method_name.name)
      buf.write_char('(')
      rust_print_arguments(buf, args)
      buf.write_char(')')
      match attr {
        NoAttr => ()
        Exclamation => buf.write_string(" /* ! */")
        Question => buf.write_char('?')
      }
    }

    // Mutation and assignment
    Mutate(record~, accessor~, field~, augmented_by~, ..) => {
      rust_print_expr(buf, record)
      buf.write_char('.')
      match accessor {
        Label(label) => buf.write_string(label.name)
        Index(tuple_index~, ..) => buf.write_string(tuple_index.to_string())
        Newtype(..) => buf.write_string("0")
      }
      match augmented_by {
        Some(op) => {
          buf.write_char(' ')
          rust_print_var(buf, op)
          buf.write_string("= ")
        }
        None => buf.write_string(" = ")
      }
      rust_print_expr(buf, field)
    }
    Assign(var_~, expr~, augmented_by~, ..) => {
      rust_print_var(buf, var_)
      match augmented_by {
        Some(op) => {
          buf.write_char(' ')
          rust_print_var(buf, op)
          buf.write_string("= ")
        }
        None => buf.write_string(" = ")
      }
      rust_print_expr(buf, expr)
    }

    // Type constraints
    Constraint(expr~, ty~, ..) => {
      rust_print_expr(buf, expr)
      buf.write_string(" as ")
      rust_print_type(buf, ty)
    }
    As(expr~, trait_~, ..) => {
      rust_print_expr(buf, expr)
      buf.write_string(" as ")
      rust_print_type_name(buf, trait_)
    }
    Is(expr~, pat~, ..) => {
      buf.write_string("matches!(")
      rust_print_expr(buf, expr)
      buf.write_string(", ")
      rust_print_pattern(buf, pat)
      buf.write_char(')')
    }

    // Control flow keywords
    Return(return_value~, ..) => {
      buf.write_string("return")
      match return_value {
        Some(e) => {
          buf.write_char(' ')
          rust_print_expr(buf, e)
        }
        None => ()
      }
    }
    Raise(err_value~, ..) => {
      buf.write_string("return Err(")
      rust_print_expr(buf, err_value)
      buf.write_char(')')
    }
    Break(arg~, ..) => {
      buf.write_string("break")
      match arg {
        Some(e) => {
          buf.write_char(' ')
          rust_print_expr(buf, e)
        }
        None => ()
      }
    }
    Continue(..) => buf.write_string("continue")

    // Error handling
    Try(body~, catch_~, try_else~, ..) =>
      if not(catch_.is_empty()) || try_else is Some(_) {
        buf.write_string("match ")
        rust_print_expr(buf, body, indent~)
        buf.write_string(" {\n")
        if not(catch_.is_empty()) {
          rust_print_indent(buf, indent + 1)
          buf.write_string("Err(e) => match e {\n")
          for c in catch_ {
            rust_print_indent(buf, indent + 2)
            rust_print_pattern(buf, c.pattern)
            buf.write_string(" => ")
            rust_print_expr(buf, c.body, indent=indent + 2)
            buf.write_string(",\n")
          }
          rust_print_indent(buf, indent + 1)
          buf.write_string("},\n")
        }
        match try_else {
          Some(cases) => {
            rust_print_indent(buf, indent + 1)
            buf.write_string("Ok(v) => match v {\n")
            for c in cases {
              rust_print_indent(buf, indent + 2)
              rust_print_pattern(buf, c.pattern)
              buf.write_string(" => ")
              rust_print_expr(buf, c.body, indent=indent + 2)
              buf.write_string(",\n")
            }
            rust_print_indent(buf, indent + 1)
            buf.write_string("},\n")
          }
          None => {
            rust_print_indent(buf, indent + 1)
            buf.write_string("Ok(v) => v,\n")
          }
        }
        rust_print_indent(buf, indent)
        buf.write_char('}')
      } else {
        rust_print_expr(buf, body, indent~)
      }
    TryOperator(body~, kind~, ..) =>
      match kind {
        Question => {
          rust_print_expr(buf, body)
          buf.write_char('?')
        }
        Exclamation => {
          rust_print_expr(buf, body)
          buf.write_string(".unwrap()")
        }
      }

    // Guard
    Guard(cond~, otherwise~, body~, ..) => {
      buf.write_string("if !(")
      rust_print_expr(buf, cond)
      buf.write_string(") {\n")
      match otherwise {
        Some(e) => {
          rust_print_indent(buf, indent + 1)
          rust_print_expr(buf, e, indent=indent + 1)
        }
        None => {
          rust_print_indent(buf, indent + 1)
          buf.write_string("panic!(\"guard failed\")")
        }
      }
      buf.write_char('\n')
      rust_print_indent(buf, indent)
      buf.write_string("}\n")
      rust_print_indent(buf, indent)
      rust_print_expr(buf, body, indent~)
    }

    // Defer
    Defer(..) => rust_todo(buf, "defer")

    // Hole
    Hole(kind~, ..) =>
      match kind {
        Synthesized => buf.write_string("todo!()")
        Incomplete => buf.write_string("todo!(\"...\")")
        Todo => buf.write_string("todo!()")
      }

    // Map
    Map(elems~, ..) => {
      buf.write_string("HashMap::from([")
      let mut first = true
      for e in elems {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        buf.write_char('(')
        rust_print_constant(buf, e.key)
        buf.write_string(", ")
        rust_print_expr(buf, e.expr)
        buf.write_char(')')
      }
      buf.write_string("])")
    }

    // Group
    Group(expr~, group~, ..) =>
      match group {
        Paren => {
          buf.write_char('(')
          rust_print_expr(buf, expr)
          buf.write_char(')')
        }
        Brace => {
          buf.write_string("{\n")
          rust_print_indent(buf, indent + 1)
          rust_print_expr(buf, expr, indent=indent + 1)
          buf.write_char('\n')
          rust_print_indent(buf, indent)
          buf.write_char('}')
        }
      }

    // String interpolation
    Interp(elems~, ..) => {
      buf.write_string("format!(\"")
      let args : Array[StringBuilder] = []
      for e in elems {
        match e {
          Literal(repr~, ..) => buf.write_string(repr)
          Expr(expr~, ..) => {
            buf.write_string("{}")
            let arg_buf = StringBuilder::new()
            rust_print_expr(arg_buf, expr)
            args.push(arg_buf)
          }
          Source(_) => ()
        }
      }
      buf.write_char('"')
      for arg in args {
        buf.write_string(", ")
        buf.write_string(arg.to_string())
      }
      buf.write_char(')')
    }
    MultilineString(..) => rust_todo(buf, "multiline string")
    LexMatch(..) => rust_todo(buf, "lexmatch")
    IsLexMatch(..) => rust_todo(buf, "is lexmatch")
    StaticAssert(body~, ..) => rust_print_expr(buf, body)
  }
}

///|
fn rust_print_var(buf : StringBuilder, v : @syntax.Var) -> Unit {
  match v.name {
    Ident(name~) => buf.write_string(name)
    Dot(pkg~, id~) => {
      buf.write_string(pkg)
      buf.write_string("::")
      buf.write_string(id)
    }
  }
}

///|
fn rust_print_arguments(
  buf : StringBuilder,
  args : @list.List[@syntax.Argument],
) -> Unit {
  let mut first = true
  for arg in args {
    if not(first) {
      buf.write_string(", ")
    }
    first = false
    match arg.kind {
      Positional => ()
      Labelled(_) => () // Rust has no labeled args; just pass the value
      LabelledPun(_) => () // For pun, the value IS the label name; just print value
      LabelledOption(..) => ()
      LabelledOptionPun(label~, ..) => {
        buf.write_string("Some(")
        buf.write_string(label.name)
        buf.write_char(')')
        continue // skip value printing
      }
    }
    rust_print_expr(buf, arg.value)
  }
}

///|
fn rust_print_closure_params(
  buf : StringBuilder,
  params : @list.List[@syntax.Parameter],
) -> Unit {
  let mut first = true
  for p in params {
    if not(first) {
      buf.write_string(", ")
    }
    first = false
    match p {
      Positional(binder~, ty~) | Labelled(binder~, ty~) => {
        buf.write_string(binder.name)
        match ty {
          Some(t) => {
            buf.write_string(": ")
            rust_print_type(buf, t)
          }
          None => ()
        }
      }
      DiscardPositional(ty~, ..) => {
        buf.write_char('_')
        match ty {
          Some(t) => {
            buf.write_string(": ")
            rust_print_type(buf, t)
          }
          None => ()
        }
      }
      Optional(binder~, ty~, ..) | QuestionOptional(binder~, ty~) => {
        buf.write_string(binder.name)
        match ty {
          Some(t) => {
            buf.write_string(": Option<")
            rust_print_type(buf, t)
            buf.write_char('>')
          }
          None => ()
        }
      }
    }
  }
}
