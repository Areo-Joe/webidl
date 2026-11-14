///|
test "Global member uniqueness includes mixins and their partial members" {
  for
    (first, second) in [
      ("attribute long value;", "readonly attribute long _value;"),
      ("const long value = 1;", "attribute long value;"),
      ("undefined run(long value);", "undefined _run(DOMString value);"),
      ("attribute long value;", "undefined value();"),
      ("stringifier attribute DOMString value;", "const long value = 1;"),
    ] {
    let global = "[Exposed=*, Global=Window] interface A"
    for
      source in [
        global +
        " { " +
        first +
        " }; interface mixin M { " +
        second +
        " }; A includes M;",
        global +
        " {}; partial interface A { " +
        first +
        " }; interface mixin M {}; partial interface mixin M { " +
        second +
        " }; A includes M;",
        global +
        " {}; interface mixin M { " +
        first +
        " }; interface mixin N { " +
        second +
        " }; A includes M; A includes N;",
        global +
        " {}; interface mixin M { " +
        first +
        " }; partial interface mixin M { " +
        second +
        " }; A includes M;",
      ] {
      assert_false(check_global_source(source))
    }
  }
}

///|
test "Global stringifier counts include original and partial mixin declarations" {
  for first in ["stringifier;", "stringifier attribute DOMString first;"] {
    for
      second in [
        "stringifier;", "stringifier readonly attribute DOMString second;",
      ] {
      for
        source in [
          "[Exposed=*, Global=Window] interface A { " +
          first +
          " }; interface mixin M { " +
          second +
          " }; A includes M;",
          "[Exposed=*, Global=Window] interface A {}; interface mixin M { " +
          first +
          " }; partial interface mixin M { " +
          second +
          " }; A includes M;",
          "[Exposed=*, Global=Window] interface A {}; interface mixin M { " +
          first +
          " }; interface mixin N {}; partial interface mixin N { " +
          second +
          " }; A includes M; A includes N;",
        ] {
        assert_false(check_global_source(source))
      }
    }
  }
}

///|
test "Global included member checks preserve separate hosts inherited members and single inclusions" {
  for
    source in [
      "[Exposed=*, Global=Window] interface A { attribute long own; }; interface mixin M { attribute long mixed; }; partial interface mixin M { const long other = 1; }; A includes M;",
      "[Exposed=*, Global=Window] interface A {}; [Exposed=*, Global=Worker] interface B {}; interface mixin M { undefined run(); }; A includes M; B includes M;",
      "[Exposed=*, Global=Window] interface A { attribute long value; }; interface mixin M { attribute long value; };",
      "[Exposed=*] interface Parent {}; interface mixin M { undefined run(); }; Parent includes M; [Exposed=*, Global=Window] interface A : Parent { undefined run(); };",
      "[Exposed=*, Global=Window] interface A {}; interface mixin M { stringifier; }; A includes M; A includes _M;",
      "[Exposed=*] interface A { undefined run(long value); }; interface mixin M { undefined run(DOMString value); }; A includes M;",
    ] {
    assert_true(check_global_source(source))
  }
}

///|
test "Global interfaces require unique member identifiers across original and partial definitions" {
  for
    (first, second) in [
      ("undefined run(long value);", "undefined run(DOMString value);"),
      ("undefined _run();", "undefined run(long value);"),
      ("attribute long value;", "readonly attribute long _value;"),
      ("const long value = 1;", "const long _value = 2;"),
      ("attribute long value;", "undefined value();"),
      ("const long value = 1;", "attribute long value;"),
      ("static undefined run();", "undefined run();"),
      (
        "static undefined run(long value);", "static undefined run(DOMString value);",
      ),
      ("static attribute long value;", "attribute long value;"),
      ("getter any lookup(DOMString key);", "any lookup(long key);"),
      (
        "stringifier attribute DOMString value;", "readonly attribute DOMString value;",
      ),
      ("inherit attribute long value;", "attribute long value;"),
      ("attribute long required;", "undefined _required();"),
      ("undefined includes();", "undefined _includes(long value);"),
    ] {
    let global = "[Exposed=*, Global=Window] interface A { "
    assert_false(check_global_source(global + first + second + " };"))
    assert_false(
      check_global_source(
        global + first + " }; partial interface A { " + second + " };",
      ),
    )
    assert_false(
      check_global_source(
        "partial interface A { " + second + " }; " + global + first + " };",
      ),
    )
    assert_false(
      check_global_source(
        global +
        " }; partial interface A { " +
        first +
        " }; partial interface A { " +
        second +
        " };",
      ),
    )
  }
}

///|
test "Global declaration counts include every form across original and partial definitions" {
  let stringifiers = [
    "stringifier;", "stringifier attribute DOMString text;", "stringifier readonly attribute DOMString other;",
  ]
  let collections = [
    "iterable<long>;", "iterable<DOMString, long>;", "async_iterable<long>;", "async_iterable<DOMString, long>;",
    "maplike<DOMString, long>;", "readonly maplike<DOMString, long>;", "setlike<long>;",
    "readonly setlike<long>;",
  ]
  for declarations in [stringifiers, collections] {
    for first in declarations {
      for second in declarations {
        let original = "[Exposed=*, Global=Window] interface A { " +
          first +
          " };"
        let partial = "partial interface A { " + second + " };"
        assert_false(
          check_global_source(
            "[Exposed=*, Global=Window] interface A { " + first + second + " };",
          ),
        )
        assert_false(check_global_source(original + partial))
        assert_false(check_global_source(partial + original))
        assert_false(
          check_global_source(
            "[Exposed=*, Global=Window] interface A {}; partial interface A { " +
            first +
            " };" +
            partial,
          ),
        )
      }
    }
  }
}

///|
test "Global uniqueness checks preserve unnamed members separate interfaces and inherited members" {
  for
    source in [
      "[Exposed=*, Global=Window] interface A { attribute long first; undefined second(); const long third = 1; };",
      "[Exposed=*, Global=Window] interface A { getter any (DOMString key); deleter boolean (DOMString key); };",
      "[Exposed=*, Global=Window] interface A {}; [Exposed=*] interface B { undefined run(long value); undefined run(DOMString value); };",
      "[Exposed=*, Global=Window] interface A { undefined run(); }; [Exposed=*, Global=Worker] interface B { undefined run(); };",
      "[Exposed=*] interface Parent { undefined run(); }; [Exposed=*, Global=Window] interface A : Parent { undefined run(); };",
      "[Exposed=*] interface Parent { stringifier; }; [Exposed=*, Global=Window] interface A : Parent { stringifier; };",
      "[Exposed=*, Global=Window] interface A { stringifier; }; partial interface A { iterable<DOMString, long>; };",
    ] {
    assert_true(check_global_source(source))
  }
  for
    declaration in [
      "stringifier;", "stringifier attribute DOMString text;", "stringifier readonly attribute DOMString text;",
      "iterable<DOMString, long>;", "async_iterable<long>;", "maplike<DOMString, long>;",
      "readonly maplike<DOMString, long>;", "setlike<long>;", "readonly setlike<long>;",
    ] {
    assert_true(
      check_global_source(
        "[Exposed=*, Global=Window] interface A { " + declaration + " };",
      ),
    )
    assert_true(
      check_global_source(
        "[Exposed=*, Global=Window] interface A {}; partial interface A { " +
        declaration +
        " };",
      ),
    )
  }
}

///|
test "Global indexed setter typedef checks are independent of getters" {
  for
    (typedef_source, argument_type, expected) in [
      ("", "unsigned long", false),
      ("typedef unsigned long Index;", "Index", false),
      ("typedef unsigned long _Index;", "_Index", false),
      ("typedef unsigned long Index;", "Index?", true),
      ("typedef unsigned long? Index;", "Index", true),
      ("typedef long Index;", "Index", true),
      ("typedef DOMString Key;", "Key", true),
    ] {
    for name in ["", "setItem"] {
      let setter = "setter undefined " +
        name +
        "(" +
        argument_type +
        " index, any value);"
      let original = "[Exposed=*, Global=Window] interface A {};"
      let partial = "partial interface A { " + setter + " };"
      for
        source in [
          "[Exposed=*, Global=Window] interface A { " + setter + " };",
          original + partial,
          partial + original,
        ] {
        let (definitions, rest) = @parser.parse(
          @lexer.tokenize(typedef_source + source).exact_view(),
        )
        assert_true(rest is [])
        let definitions = Definition::from_parser(definitions)
        let typedefs = Map([])
        for definition in definitions {
          if definition is Typedef(typedef_) {
            typedefs.set(strip_underscore(typedef_.identifier), typedef_)
          }
        }
        let interfaces = definitions.filter_map(definition => {
          if definition is Interface(interface) {
            Some(interface)
          } else {
            None
          }
        })
        assert_eq(interfaces.length(), 1)
        let accepted = try
          check_global_interface_no_indexed_getter_or_setter(
            interfaces[0],
            typedefs,
          )
        catch {
          _ => false
        } noraise {
          _ => true
        }
        assert_eq(accepted, expected)
      }
    }
  }
}

///|
test "Global property restrictions resolve typedefs on original and partial members" {
  for
    (typedef_source, members, expected) in [
      (
        "typedef DOMString Key;", "getter any (DOMString key); setter undefined (Key key, any value);",
        false,
      ),
      (
        "typedef DOMString _Key;", "getter any (DOMString key); setter undefined (_Key key, any value);",
        false,
      ),
      (
        "typedef unsigned long Index;", "attribute unsigned long length; getter any (Index index);",
        false,
      ),
      (
        "typedef unsigned long Index;", "attribute unsigned long length; getter any (Index index); setter undefined (Index index, any value);",
        false,
      ),
      ("typedef USVString Key;", "setter undefined (Key key, any value);", true),
      (
        "typedef long Index;", "getter any (Index index); setter undefined (Index index, any value);",
        true,
      ),
      (
        "typedef DOMString? Key;", "setter undefined (Key key, any value);", true,
      ),
      (
        "typedef unsigned long? Index;", "getter any (Index index); setter undefined (Index index, any value);",
        true,
      ),
    ] {
    assert_eq(
      check_global_source(
        typedef_source +
        "[Exposed=*, Global=Window] interface A { " +
        members +
        " };",
      ),
      expected,
    )
    let original = "[Exposed=*, Global=Window] interface A {};"
    let partial = "partial interface A { " + members + " };"
    assert_eq(
      check_global_source(typedef_source + original + partial),
      expected,
    )
    assert_eq(
      check_global_source(typedef_source + partial + original),
      expected,
    )
  }
}

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
  for
    attrs in [
      "[Exposed=*, Global=Window]", "[Exposed=*, Global=(Window,Worker)]",
    ] {
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
  assert_true(
    check_global_source("[Exposed=*] interface A { constructor(); };"),
  )
  assert_true(
    check_global_source(
      "[Exposed=*, Global=Window] interface A {}; [Exposed=*] interface B { constructor(); };",
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
        let original = "[Exposed=*] interface A { " + body + " };"
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
    assert_true(check_global_source("[Exposed=*, " + global_attr + "]" + body))
    for
      attrs in [
        "[Exposed=*, " + global_attr + ", LegacyOverrideBuiltIns]",
        "[Exposed=*, LegacyOverrideBuiltIns, " + global_attr + "]",
      ] {
      assert_false(check_global_source(attrs + body))
    }
  }
  assert_true(check_global_source("[Exposed=*, LegacyOverrideBuiltIns]" + body))
  assert_true(check_global_source("[Exposed=*]" + body))
  assert_true(
    check_global_source(
      "[Exposed=*, Global=Window] interface A {}; [Exposed=*, LegacyOverrideBuiltIns] interface B { getter any (DOMString name); };",
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
    let accepted = try
      check_global_interface_no_named_setter(interface, Map([]))
    catch {
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
      check_global_interface_no_indexed_getter_or_setter(interface, Map([]))
    catch {
      _ => false
    } noraise {
      _ => true
    }
    assert_eq(accepted, valid)
  }
}

///|
test "Global partial must define a named getter in that partial" {
  for attrs in ["[Global=Window]", "[Global=(Window,Worker)]"] {
    for
      (body, valid) in [
        ("getter any (DOMString name);", true),
        ("getter any item(DOMString name);", true),
        ("undefined f(); getter any (DOMString name);", true),
        ("", false),
        ("any item(DOMString name);", false),
        ("static any item(DOMString name);", false),
        ("setter undefined (DOMString name, any value);", false),
        ("deleter boolean (DOMString name);", false),
        ("getter any ();", false),
        ("getter any (DOMString name, any extra);", false),
        ("getter any (unsigned long index);", false),
        ("getter any (DOMString? name);", false),
        ("getter any (USVString name);", false),
        ("getter any (ByteString name);", false),
      ] {
      let original = "[Exposed=*] interface A {};"
      let partial = attrs + " partial interface A { " + body + " };"
      assert_eq(check_global_source(original + partial), valid)
      assert_eq(check_global_source(partial + original), valid)
    }
  }
  assert_true(
    check_global_source("[Exposed=*] interface A {}; partial interface A {};"),
  )
}

///|
test "Global partial cannot use a named getter declared elsewhere" {
  for
    source in [
      "[Exposed=*] interface A { getter any (DOMString name); }; [Global=Window] partial interface A {};",
      "[Exposed=*] interface A {}; partial interface A { getter any (DOMString name); }; [Global=Window] partial interface A {};",
      "[Exposed=*] interface A {}; [Global=Window] partial interface A { getter any (DOMString name); }; [Global=Worker] partial interface A {};",
      "[Exposed=*] interface A : Parent {}; [Exposed=*] interface Parent { getter any (DOMString name); }; [Global=Window] partial interface A {};",
      "[Exposed=*] interface A {}; [Exposed=*] interface B { getter any (DOMString name); }; [Global=Window] partial interface A {};",
    ] {
    assert_false(check_global_source(source))
  }
  assert_true(
    check_global_source(
      "[Exposed=*] interface A {}; partial interface A {}; [Global=Window] partial interface A { getter any (DOMString name); }; partial interface A { undefined f(); };",
    ),
  )
}
