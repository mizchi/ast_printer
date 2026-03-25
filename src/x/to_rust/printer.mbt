///|
/// Print indentation (4 spaces per level, Rust convention).
fn rust_print_indent(buf : StringBuilder, indent : Int) -> Unit {
  for _ in 0..<indent {
    buf.write_string("    ")
  }
}

///|
/// Emit a TODO comment for unsupported features with reason and fix hint.
fn rust_todo(
  buf : StringBuilder,
  feature : String,
  reason? : String = "",
  hint? : String = "",
) -> Unit {
  buf.write_string("/* TODO(transpile): ")
  buf.write_string(feature)
  if reason.length() > 0 {
    buf.write_string("\n * Reason: ")
    buf.write_string(reason)
  }
  if hint.length() > 0 {
    buf.write_string("\n * Fix: ")
    buf.write_string(hint)
  }
  buf.write_string(" */")
}

///|
/// Convert MoonBit impls to Rust code string.
pub fn to_rust(impls : @syntax.Impls) -> String {
  let buf = StringBuilder::new()
  for impl_ in impls {
    rust_print_impl(buf, impl_)
    buf.write_char('\n')
  }
  buf.to_string()
}

///|
/// Print a single top-level implementation as Rust.
fn rust_print_impl(buf : StringBuilder, impl_ : @syntax.Impl) -> Unit {
  match impl_ {
    TopFuncDef(fun_decl~, decl_body~, ..) => {
      rust_print_fun_decl(buf, fun_decl)
      rust_print_decl_body(buf, decl_body)
    }
    TopTypeDef(type_decl) => rust_print_type_decl(buf, type_decl)
    TopLetDef(binder~, ty~, expr~, vis~, is_constant~, attrs~, doc~, ..) => {
      rust_print_doc_string(buf, doc)
      rust_print_rust_attrs(buf, attrs)
      rust_print_visibility(buf, vis)
      if is_constant {
        buf.write_string("const ")
      } else {
        buf.write_string("static ")
      }
      buf.write_string(rust_convert_name(binder.name))
      match ty {
        Some(t) => {
          buf.write_string(": ")
          rust_print_type(buf, t)
        }
        None => ()
      }
      buf.write_string(" = ")
      rust_print_expr(buf, expr)
      buf.write_char(';')
    }
    TopTest(..) => () // skip test blocks
    TopTrait(trait_decl) => rust_print_trait_decl(buf, trait_decl)
    TopImpl(
      self_ty~,
      trait_~,
      method_name~,
      quantifiers~,
      params~,
      ret_ty~,
      body~,
      ..
    ) => {
      buf.write_string("impl")
      rust_print_quantifiers(buf, quantifiers)
      buf.write_char(' ')
      rust_print_type_name(buf, trait_)
      match self_ty {
        Some(t) => {
          buf.write_string(" for ")
          rust_print_type(buf, t)
        }
        None => ()
      }
      buf.write_string(" {\n")
      rust_print_indent(buf, 1)
      buf.write_string("fn ")
      buf.write_string(rust_convert_name(method_name.name))
      buf.write_char('(')
      // Add &self as first param for trait impl methods
      buf.write_string("&self")
      if not(params.is_empty()) {
        buf.write_string(", ")
      }
      rust_print_parameters(buf, params)
      buf.write_char(')')
      match ret_ty {
        Some(t) => {
          buf.write_string(" -> ")
          rust_print_type(buf, t)
        }
        None => ()
      }
      buf.write_char(' ')
      rust_print_decl_body(buf, body, indent=1)
      buf.write_char('\n')
      buf.write_char('}')
    }
    TopExpr(expr~, ..) => {
      rust_print_expr(buf, expr)
      buf.write_char(';')
    }
    TopView(..) =>
      rust_todo(
        buf,
        "enumview",
        reason="MoonBit enumview (pattern views) has no Rust equivalent.",
        hint="Implement as a function that returns an enum for pattern matching, or use a match with manual destructuring.",
      )
    TopImplRelation(self_ty~, trait_~, quantifiers~, vis~, ..) => {
      rust_print_visibility(buf, vis)
      buf.write_string("impl")
      rust_print_quantifiers(buf, quantifiers)
      buf.write_char(' ')
      rust_print_type_name(buf, trait_)
      buf.write_string(" for ")
      rust_print_type(buf, self_ty)
      buf.write_string(" {}")
    }
    TopUsing(..) =>
      rust_todo(
        buf,
        "using (import alias)",
        reason="MoonBit `using` re-exports types/values from another package.",
        hint="Replace with `use crate::module::Type;` or `pub use` for re-exports.",
      )
  }
}

///|
/// Convert MoonBit name to Rust snake_case (basic: just return as-is for now).
fn rust_convert_name(name : String) -> String {
  name
}

///|
fn rust_print_fun_decl(buf : StringBuilder, decl : @syntax.FunDecl) -> Unit {
  rust_print_visibility(buf, decl.vis)
  buf.write_string("fn ")
  match decl.type_name {
    // Self:: method syntax not applicable at top level in Rust
    Some(_) => ()
    None => ()
  }
  buf.write_string(rust_convert_name(decl.name.name))
  rust_print_quantifiers(buf, decl.quantifiers)
  buf.write_char('(')
  match decl.decl_params {
    Some(params) => rust_print_parameters(buf, params)
    None => ()
  }
  buf.write_char(')')
  match decl.return_type {
    Some(t) =>
      if not(rust_is_unit_type(t)) {
        buf.write_string(" -> ")
        rust_print_type(buf, t)
      }
    None => ()
  }
  buf.write_char(' ')
}

///|
fn rust_print_decl_body(
  buf : StringBuilder,
  body : @syntax.DeclBody,
  indent? : Int = 0,
) -> Unit {
  match body {
    DeclBody(expr~, ..) => {
      buf.write_string("{\n")
      rust_print_indent(buf, indent + 1)
      rust_print_expr(buf, expr, indent=indent + 1)
      buf.write_char('\n')
      rust_print_indent(buf, indent)
      buf.write_char('}')
    }
    DeclStubs(_) =>
      rust_todo(
        buf,
        "extern function stub",
        reason="MoonBit FFI stubs (extern) require platform-specific Rust FFI binding.",
        hint="Use `extern \"C\" { fn name(...) -> ...; }` or link via `#[link]` attribute.",
      )
    DeclNone => buf.write_string("{}")
  }
}

///|
fn rust_print_type_decl(buf : StringBuilder, decl : @syntax.TypeDecl) -> Unit {
  match decl.components {
    Variant(constrs) => {
      rust_print_visibility(buf, decl.type_vis)
      buf.write_string("enum ")
      buf.write_string(decl.tycon)
      rust_print_type_params(buf, decl.params)
      buf.write_string(" {\n")
      for constr in constrs {
        rust_print_indent(buf, 1)
        buf.write_string(constr.name.name)
        match constr.args {
          Some(args) if not(args.is_empty()) => {
            buf.write_char('(')
            rust_print_constr_params(buf, args)
            buf.write_char(')')
          }
          _ => ()
        }
        buf.write_string(",\n")
      }
      buf.write_char('}')
    }
    Record(fields~, ..) => {
      rust_print_visibility(buf, decl.type_vis)
      buf.write_string("struct ")
      buf.write_string(decl.tycon)
      rust_print_type_params(buf, decl.params)
      buf.write_string(" {\n")
      for field in fields {
        rust_print_indent(buf, 1)
        // In Rust, struct fields are private by default; emit pub for non-priv fields
        match field.vis {
          Priv(..) => ()
          _ => buf.write_string("pub ")
        }
        if field.mut_ {
          buf.write_string(
            "/* NOTE: mutable field in MoonBit. In Rust, use &mut self methods or Cell/RefCell. */ ",
          )
        }
        buf.write_string(field.name.label)
        buf.write_string(": ")
        rust_print_type(buf, field.ty)
        buf.write_string(",\n")
      }
      buf.write_char('}')
    }
    Alias(ty) => {
      rust_print_visibility(buf, decl.type_vis)
      buf.write_string("type ")
      buf.write_string(decl.tycon)
      rust_print_type_params(buf, decl.params)
      buf.write_string(" = ")
      rust_print_type(buf, ty)
      buf.write_char(';')
    }
    Abstract => {
      rust_print_visibility(buf, decl.type_vis)
      buf.write_string("struct ")
      buf.write_string(decl.tycon)
      rust_print_type_params(buf, decl.params)
      buf.write_char(';')
    }
    Extern => {
      rust_print_visibility(buf, decl.type_vis)
      buf.write_string("/* extern */ struct ")
      buf.write_string(decl.tycon)
      rust_print_type_params(buf, decl.params)
      buf.write_char(';')
    }
    TupleStruct(tys) => {
      rust_print_visibility(buf, decl.type_vis)
      buf.write_string("struct ")
      buf.write_string(decl.tycon)
      rust_print_type_params(buf, decl.params)
      buf.write_char('(')
      rust_print_type_list(buf, tys)
      buf.write_string(");")
    }
    Error(ex_decl) => {
      rust_print_visibility(buf, decl.type_vis)
      buf.write_string("/* suberror */ enum ")
      buf.write_string(decl.tycon)
      match ex_decl {
        NoPayload => buf.write_string(" {}")
        SinglePayload(ty) => {
          buf.write_char('(')
          rust_print_type(buf, ty)
          buf.write_string(");")
        }
        EnumPayload(constrs) => {
          buf.write_string(" {\n")
          for constr in constrs {
            rust_print_indent(buf, 1)
            buf.write_string(constr.name.name)
            match constr.args {
              Some(args) if not(args.is_empty()) => {
                buf.write_char('(')
                rust_print_constr_params(buf, args)
                buf.write_char(')')
              }
              _ => ()
            }
            buf.write_string(",\n")
          }
          buf.write_char('}')
        }
      }
    }
  }
  if not(decl.deriving.is_empty()) {
    // Note: derive is printed before the type in Rust, but we append as comment for now
    buf.write_string(" /* derive(")
    let mut first = true
    for d in decl.deriving {
      if not(first) {
        buf.write_string(", ")
      }
      first = false
      rust_print_type_name(buf, d.type_name)
    }
    buf.write_string(") */")
  }
}

///|
fn rust_print_trait_decl(buf : StringBuilder, decl : @syntax.TraitDecl) -> Unit {
  rust_print_visibility(buf, decl.vis)
  buf.write_string("trait ")
  buf.write_string(decl.name.name)
  if not(decl.supers.is_empty()) {
    buf.write_string(": ")
    let mut first = true
    for super_ in decl.supers {
      if not(first) {
        buf.write_string(" + ")
      }
      first = false
      rust_print_long_ident(buf, super_.trait_)
    }
  }
  buf.write_string(" {\n")
  for m in decl.methods {
    rust_print_indent(buf, 1)
    buf.write_string("fn ")
    buf.write_string(rust_convert_name(m.name.name))
    buf.write_char('(')
    buf.write_string("&self")
    // Filter out Self/DiscardPositional(Self) params, print the rest
    let non_self_params = m.params.filter(fn(p) {
      match p {
        DiscardPositional(ty~, ..) =>
          match ty {
            Some(Name(constr_id~, ..)) =>
              match constr_id.id {
                Ident(name~) => name != "Self"
                _ => true
              }
            _ => true
          }
        _ => true
      }
    })
    if not(non_self_params.is_empty()) {
      buf.write_string(", ")
    }
    rust_print_parameters(buf, non_self_params)
    buf.write_char(')')
    match m.return_type {
      Some(t) =>
        if not(rust_is_unit_type(t)) {
          buf.write_string(" -> ")
          rust_print_type(buf, t)
        }
      None => ()
    }
    buf.write_string(";\n")
  }
  buf.write_char('}')
}

///|
fn rust_print_visibility(buf : StringBuilder, vis : @syntax.Visibility) -> Unit {
  match vis {
    Default => ()
    Pub(attr~, ..) =>
      match attr {
        Some("all") | None => buf.write_string("pub ")
        Some("open") => buf.write_string("pub ")
        Some(a) => {
          buf.write_string("pub(")
          buf.write_string(a)
          buf.write_string(") ")
        }
      }
    Priv(..) => () // private is default in Rust
  }
}

///|
/// Print MoonBit doc string as Rust doc comment.
fn rust_print_doc_string(buf : StringBuilder, doc : @syntax.DocString) -> Unit {
  for line in doc.content {
    buf.write_string("///")
    buf.write_string(line)
    buf.write_char('\n')
  }
}

///|
fn rust_print_quantifiers(
  buf : StringBuilder,
  quantifiers : @list.List[@syntax.TypeVarBinder],
) -> Unit {
  if not(quantifiers.is_empty()) {
    buf.write_char('<')
    let mut first = true
    for q in quantifiers {
      if not(first) {
        buf.write_string(", ")
      }
      first = false
      buf.write_string(q.name)
      if not(q.constraints.is_empty()) {
        buf.write_string(": ")
        let mut first_c = true
        for c in q.constraints {
          if not(first_c) {
            buf.write_string(" + ")
          }
          first_c = false
          rust_print_long_ident(buf, c.trait_)
        }
      }
    }
    buf.write_char('>')
  }
}

///|
fn rust_print_type_params(
  buf : StringBuilder,
  params : @list.List[@syntax.TypeDeclBinder],
) -> Unit {
  if not(params.is_empty()) {
    buf.write_char('<')
    let mut first = true
    for p in params {
      if not(first) {
        buf.write_string(", ")
      }
      first = false
      match p.name {
        Some(name) => buf.write_string(name)
        None => buf.write_char('_')
      }
    }
    buf.write_char('>')
  }
}

///|
fn rust_print_constr_params(
  buf : StringBuilder,
  params : @list.List[@syntax.ConstrParam],
) -> Unit {
  let mut first = true
  for p in params {
    if not(first) {
      buf.write_string(", ")
    }
    first = false
    match p.label {
      Some(label) => {
        buf.write_string(label.name)
        buf.write_string(": ")
      }
      None => ()
    }
    rust_print_type(buf, p.ty)
  }
}

///|
fn rust_print_parameters(
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
      Positional(binder~, ty~) => {
        buf.write_string(rust_convert_name(binder.name))
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
      Labelled(binder~, ty~) => {
        // Rust has no labeled args, emit as positional
        buf.write_string(rust_convert_name(binder.name))
        match ty {
          Some(t) => {
            buf.write_string(": ")
            rust_print_type(buf, t)
          }
          None => ()
        }
      }
      Optional(binder~, ty~, ..) => {
        // Rust has no optional args, wrap type in Option
        buf.write_string(rust_convert_name(binder.name))
        match ty {
          Some(t) => {
            buf.write_string(": Option<")
            rust_print_type(buf, t)
            buf.write_char('>')
          }
          None => ()
        }
      }
      QuestionOptional(binder~, ty~) => {
        buf.write_string(rust_convert_name(binder.name))
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

///|
fn rust_print_rust_attrs(
  buf : StringBuilder,
  attrs : @list.List[@attribute.Attribute],
) -> Unit {
  for attr in attrs {
    buf.write_string("// ")
    buf.write_string(attr.raw)
    buf.write_char('\n')
  }
}
