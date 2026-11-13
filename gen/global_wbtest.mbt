///|
fn parse_global_attributes(
  source : String,
) -> @parser.ExtendedAttributeList raise {
  let (attrs, rest) = @parser.ExtendedAttributeList::parse(
    @lexer.tokenize(source).exact_view(),
  )
  assert_true(rest is [])
  attrs
}

///|
fn check_global_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Global recognizes identifier and identifier list forms" {
  let attrs = parse_global_attributes(
    "[Global=_Window, Global=(_Window,Worker)]",
  )
  let recognized = attrs.iter().filter_map(is_valid_global).collect()
  assert_eq(recognized.length(), 2)
  assert_true(recognized[0] is Ident("_Window"))
  guard recognized[1] is IdentList(names) else {
    fail("expected identifier list")
  }
  assert_eq(names, ["_Window", "Worker"])
  assert_eq(global_names(attrs), ["Window", "Window", "Worker"])
}

///|
test "Global leaves other forms and other attribute names unrecognized" {
  for
    source in [
      "[Global]", "[Global()]", "[Global=Window()]", "[Global=*]", "[Global=\"Window\"]",
      "[Global=1]", "[Global=1.5]", "[Global=(1,2)]", "[Exposed=Window]", "[Exposed=(Window,Worker)]",
      "[global=Window]",
    ] {
    let attrs = parse_global_attributes(source)
    assert_eq(attrs.iter().count(), 1)
    assert_true(attrs.iter().all(attr => is_valid_global(attr) is None))
    assert_eq(global_names(attrs), [])
  }
}

///|
test "Global names extraction keeps order and duplicates while ignoring other forms" {
  assert_eq(
    global_names(
      parse_global_attributes(
        "[Exposed=Window, Global=Window, Global, Global=(_Worker,Window), Global=*]",
      ),
    ),
    ["Window", "Worker", "Window"],
  )
  assert_eq(global_names(parse_global_attributes("")), [])
}

///|
test "Global interface cannot define constructors" {
  for attrs in ["[Global=Window]", "[Global=(Window,Worker)]"] {
    for body in ["", "undefined f();"] {
      assert_true(check_global_source(attrs + " interface A { " + body + " };"))
      for
        constructor_source in [
          "constructor();", "constructor(DOMString value);",
        ] {
        assert_false(
          check_global_source(
            attrs + " interface A { " + body + constructor_source + " };",
          ),
        )
      }
    }
  }
  assert_true(check_global_source("interface A { constructor(); };"))
  assert_true(
    check_global_source(
      "[Global=Window] interface A {}; interface B { constructor(); };",
    ),
  )
}

///|
test "Global constructor check only uses the original interface annotation" {
  for attrs in ["[Global=Window]", "[Global=(Window,Worker)]"] {
    let partial = attrs +
      " partial interface A { getter any (DOMString name); };"
    for partial_first in [true, false] {
      for body in ["", "constructor();"] {
        let original = "interface A { " + body + " };"
        let source = if partial_first {
          partial + original
        } else {
          original + partial
        }
        let (definitions, rest) = @parser.parse(
          @lexer.tokenize(source).exact_view(),
        )
        assert_true(rest is [])
        for definition in Definition::from_parser(definitions) {
          if definition is Interface(interface) {
            check_global_interface_no_constructor(interface)
          }
        }
      }
    }
  }
}

///|
test "LegacyOverrideBuiltIns recognizes only the no arguments form" {
  for
    (source, valid) in [
      ("[LegacyOverrideBuiltIns]", true),
      ("[LegacyOverrideBuiltIns()]", false),
      ("[LegacyOverrideBuiltIns=Value()]", false),
      ("[LegacyOverrideBuiltIns=Value]", false),
      ("[LegacyOverrideBuiltIns=(Value,Other)]", false),
      ("[LegacyOverrideBuiltIns=*]", false),
      ("[LegacyOverrideBuiltIns=\"Value\"]", false),
      ("[LegacyOverrideBuiltIns=1]", false),
      ("[LegacyOverrideBuiltIns=1.5]", false),
      ("[LegacyOverrideBuiltIns=(1,2)]", false),
      ("[SecureContext]", false),
      ("[legacyOverrideBuiltIns]", false),
    ] {
    let attrs = parse_global_attributes(source)
    assert_eq(attrs.iter().count(), 1)
    assert_eq(attrs.iter().any(is_valid_legacy_override_built_ins), valid)
  }
}

///|
test "Global and LegacyOverrideBuiltIns cannot annotate the same interface" {
  let body = " interface A { getter any (DOMString name); };"
  for global_attr in ["Global=Window", "Global=(Window,Worker)"] {
    assert_true(check_global_source("[" + global_attr + "]" + body))
    for
      attrs in [
        "[" + global_attr + ", LegacyOverrideBuiltIns]",
        "[LegacyOverrideBuiltIns, " + global_attr + "]",
      ] {
      assert_false(check_global_source(attrs + body))
    }
  }
  assert_true(check_global_source("[LegacyOverrideBuiltIns]" + body))
  assert_true(check_global_source(body))
  assert_true(
    check_global_source(
      "[Global=Window] interface A {}; [LegacyOverrideBuiltIns] interface B { getter any (DOMString name); };",
    ),
  )
}
