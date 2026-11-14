///|
test "constant names are unescaped before validation" {
  for
    source in [
      "[Exposed=*] interface A { const long _value = 1; };", "[Exposed=*] interface A {}; partial interface A { const long _value = 1; };",
      "interface mixin M { const long _value = 1; };", "interface mixin M {}; partial interface mixin M { const long _value = 1; };",
      "callback interface C { const long _value = 1; undefined run(); };",
    ] {
    let (definitions, rest) = @parser.parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    doc(definitions)
  }
}

///|
test "escaped reserved constant names are rejected" {
  for name in ["_constructor", "_toString", "_toJSON"] {
    let source = "[Exposed=*] interface A { const long " + name + " = 1; };"
    let (definitions, rest) = @parser.parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    let raised = try doc(definitions) catch {
      _ => true
    } noraise {
      _ => false
    }
    assert_true(raised)
  }
}
