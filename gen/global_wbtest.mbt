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
        assert_true(check_global_source(source))
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

///|
test "Global interface cannot inherit LegacyOverrideBuiltIns along its inheritance chain" {
  for global_attr in ["Global=Window", "Global=(Window,Worker)"] {
    for
      (parents, valid) in [
        ("[Exposed=*] interface Parent {};", true),
        (
          "[Exposed=*, LegacyOverrideBuiltIns] interface Parent { getter any (DOMString name); };",
          false,
        ),
        (
          "[Exposed=*] interface Parent : Root {}; [Exposed=*] interface Root {};",
          true,
        ),
        (
          "[Exposed=*] interface Parent : Root {}; [Exposed=*, LegacyOverrideBuiltIns] interface Root { getter any (DOMString name); };",
          false,
        ),
        (
          "[Exposed=*] interface Parent : Middle {}; [Exposed=*, LegacyOverrideBuiltIns] interface Middle : Root { getter any (DOMString name); }; [Exposed=*] interface Root {};",
          false,
        ),
        (
          "[Exposed=*] interface Parent : Middle {}; [Exposed=*] interface Middle : Root {}; [Exposed=*, LegacyOverrideBuiltIns] interface Root { getter any (DOMString name); };",
          false,
        ),
      ] {
      let child = "[Exposed=*, " +
        global_attr +
        "] interface Child : Parent {};"
      assert_eq(check_global_source(child + parents), valid)
      assert_eq(check_global_source(parents + child), valid)
    }
  }
}

///|
test "Global inheritance restriction is limited to global interfaces and their ancestors" {
  assert_true(
    check_global_source(
      "[Exposed=*] interface Child : Parent {}; [Exposed=*, LegacyOverrideBuiltIns] interface Parent { getter any (DOMString name); };",
    ),
  )
  assert_true(
    check_global_source(
      "[Exposed=*, Global=Window] interface A {}; [Exposed=*] interface Child : Parent {}; [Exposed=*, LegacyOverrideBuiltIns] interface Parent { getter any (DOMString name); };",
    ),
  )
  assert_false(
    check_global_source(
      "[Exposed=*, Global=Window] interface Child : _Parent {}; [Exposed=*, LegacyOverrideBuiltIns] interface Parent { getter any (DOMString name); };",
    ),
  )
}

///|
test "Interfaces cannot inherit from global interfaces" {
  for global_attr in ["Global=Window", "Global=(Window,Worker)"] {
    for child_attrs in ["[Exposed=*]", "[Exposed=*, Global=Other]"] {
      let child = child_attrs + " interface Child : Parent {};"
      let parent = "[Exposed=*, " + global_attr + "] interface Parent {};"
      assert_false(check_global_source(child + parent))
      assert_false(check_global_source(parent + child))
      assert_false(
        check_global_source(
          child_attrs +
          " interface Child : Middle {}; [Exposed=*] interface Middle : Parent {};" +
          parent,
        ),
      )
    }
  }
  assert_false(
    check_global_source(
      "[Exposed=*] interface Child : _Parent {}; [Exposed=*, Global=_Window] interface Parent {};",
    ),
  )
}

///|
test "Global interfaces may inherit ordinary interfaces and coexist with unrelated inheritance" {
  for
    source in [
      "[Exposed=*] interface Child : Parent {}; [Exposed=*] interface Parent {};",
      "[Exposed=*, Global=Window] interface Child : Parent {}; [Exposed=*] interface Parent : Root {}; [Exposed=*] interface Root {};",
      "[Exposed=*, Global=Window] interface A {}; [Exposed=*] interface Child : Parent {}; [Exposed=*] interface Parent {};",
    ] {
    assert_true(check_global_source(source))
  }
}

///|
test "Global interface cannot define named setters on the original or partials" {
  for
    attrs in [
      "[Exposed=*, Global=Window]", "[Exposed=*, Global=(Window,Worker)]",
    ] {
    for
      setter_source in [
        "setter undefined (DOMString name, any value);", "setter undefined setItem(DOMString name, any value);",
      ] {
      let body = "getter any (DOMString name); " + setter_source
      assert_false(
        check_global_source(attrs + " interface A { " + body + " };"),
      )
      let original = attrs + " interface A {};"
      let partial = "partial interface A { " + body + " };"
      assert_false(check_global_source(original + partial))
      assert_false(check_global_source(partial + original))
      assert_false(
        check_global_source(
          original + "partial interface A { undefined first(); };" + partial,
        ),
      )
      assert_true(
        check_global_source("[Exposed=*] interface A { " + body + " };"),
      )
    }
  }
  assert_true(
    check_global_source(
      "[Exposed=*, Global=Window] interface A { getter any (DOMString name); undefined setItem(DOMString name, any value); };",
    ),
  )
  assert_true(
    check_global_source(
      "[Exposed=*, Global=Window] interface A {}; [Exposed=*] interface B { getter any (DOMString name); setter undefined (DOMString name, any value); };",
    ),
  )
}

///|
test "Global named setter check uses only setter argument count and first argument type" {
  for
    (body, valid) in [
      ("setter undefined (DOMString name, long value);", false),
      ("setter undefined ();", true),
      ("setter undefined (DOMString name);", true),
      ("setter undefined (DOMString name, any value, any extra);", true),
      ("setter undefined (unsigned long index, any value);", true),
      ("setter undefined (USVString name, any value);", true),
      ("setter undefined (ByteString name, any value);", true),
      ("setter undefined (DOMString? name, any value);", true),
      ("setter undefined ((DOMString or long) name, any value);", true),
      ("getter any (DOMString name, any value);", true),
      ("deleter boolean (DOMString name, any value);", true),
      ("static undefined setItem(DOMString name, any value);", true),
      ("setter undefined (optional DOMString name, any value);", false),
      ("setter undefined (DOMString name, optional any value);", false),
      ("setter undefined (DOMString... name, any value);", false),
      ("setter undefined (DOMString name, any... value);", false),
    ] {
    let (definitions, rest) = @parser.parse(
      @lexer.tokenize("[Global=Window] interface A { " + body + " };").exact_view(),
    )
    assert_true(rest is [])
    guard Definition::from_parser(definitions)[0] is Interface(interface) else {
      fail("expected interface")
    }
    let accepted = try check_global_interface_no_named_setter(interface) catch {
      _ => false
    } noraise {
      _ => true
    }
    assert_eq(accepted, valid)
  }
}

///|
test "Global interface cannot define indexed getters or setters on the original or partials" {
  for
    attrs in [
      "[Exposed=*, Global=Window]", "[Exposed=*, Global=(Window,Worker)]",
    ] {
    for
      operation_source in [
        "getter any (unsigned long index);", "getter any item(unsigned long index);",
        "setter undefined (unsigned long index, any value);", "setter undefined setItem(unsigned long index, any value);",
      ] {
      assert_false(
        check_global_source(
          attrs + " interface A { " + operation_source + " };",
        ),
      )
      let original = attrs + " interface A {};"
      let partial = "partial interface A { " + operation_source + " };"
      assert_false(check_global_source(original + partial))
      assert_false(check_global_source(partial + original))
      assert_false(
        check_global_source(
          original + "partial interface A { undefined first(); };" + partial,
        ),
      )
    }
  }
  let ordinary = "[Exposed=*] interface B { readonly attribute unsigned long length; getter any (unsigned long index); setter undefined (unsigned long index, any value); };"
  assert_true(check_global_source(ordinary))
  assert_true(
    check_global_source("[Exposed=*, Global=Window] interface A {};" + ordinary),
  )
  assert_true(
    check_global_source(
      "[Exposed=*, Global=Window] interface A { getter any (DOMString name); any item(unsigned long index); undefined setItem(unsigned long index, any value); };",
    ),
  )
}

///|
test "Global indexed getter or setter check uses keyword argument count and unsigned long type" {
  for
    (body, valid) in [
      ("getter any ();", true),
      ("getter any (unsigned long index, any extra);", true),
      ("setter undefined (unsigned long index);", true),
      ("setter undefined (unsigned long index, any value, any extra);", true),
      ("deleter boolean (unsigned long index);", true),
      ("static any item(unsigned long index);", true),
      ("getter any (DOMString name);", true),
      ("setter undefined (DOMString name, any value);", true),
      ("getter any (long index);", true),
      ("getter any (unsigned short index);", true),
      ("getter any (unsigned long long index);", true),
      ("getter any (unsigned long? index);", true),
      ("setter undefined (long index, any value);", true),
      ("setter undefined (unsigned short index, any value);", true),
      ("setter undefined (unsigned long long index, any value);", true),
      ("setter undefined (unsigned long? index, any value);", true),
      ("getter any (optional unsigned long index);", false),
      ("getter any (unsigned long... index);", false),
      ("setter undefined (optional unsigned long index, any value);", false),
      ("setter undefined (unsigned long index, optional any value);", false),
      ("setter undefined (unsigned long index, any... value);", false),
    ] {
    let (definitions, rest) = @parser.parse(
      @lexer.tokenize("[Global=Window] interface A { " + body + " };").exact_view(),
    )
    assert_true(rest is [])
    guard Definition::from_parser(definitions)[0] is Interface(interface) else {
      fail("expected interface")
    }
    let accepted = try
      check_global_interface_no_indexed_getter_or_setter(interface)
    catch {
      _ => false
    } noraise {
      _ => true
    }
    assert_eq(accepted, valid)
  }
}
