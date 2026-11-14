///|
fn check_interface_mixin_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Interface mixins cannot supply direct or nested operation types" {
  for
    type_ in [
      "M", "_M", "M?", "sequence<M>", "async_sequence<M>", "record<DOMString, M>",
      "Promise<M>", "FrozenArray<M>", "ObservableArray<M>", "(M or DOMString)", "sequence<record<DOMString, Promise<M?>>>",
    ] {
    for
      member_ in [
        type_ + " run();",
        "undefined run(" + type_ + " value);",
        "undefined run(optional " + type_ + " value);",
        "undefined run(" + type_ + "... values);",
      ] {
      let interface_ = "[Exposed=*] interface A { " + member_ + " };"
      assert_false(
        check_interface_mixin_source("interface mixin M {};" + interface_),
      )
      assert_false(
        check_interface_mixin_source(interface_ + "interface mixin _M {};"),
      )
    }
  }
}

///|
test "Interface mixin type checks reach declaration entry points" {
  for
    declaration in [
      "[Exposed=*] interface A { attribute M value; };", "[Exposed=*] interface A { static attribute M value; };",
      "[Exposed=*] interface A { stringifier attribute M value; };", "[Exposed=*] interface A { constructor(M value); };",
      "[Exposed=*] interface A { static M run(); };", "[Exposed=*] interface A {}; partial interface A { M run(); };",
      "interface mixin N { attribute M value; };", "interface mixin N {}; partial interface mixin N { M run(); };",
      "namespace N { readonly attribute M value; };", "namespace N { M run(); };",
      "namespace N {}; partial namespace N { M run(); };", "dictionary D { M value; };",
      "dictionary D {}; partial dictionary D { required M value; };", "callback C = M ();",
      "callback C = undefined (M value);", "callback interface C { M run(); };",
      "[Exposed=*, LegacyFactoryFunction=Create(M value)] interface A {};", "[Exposed=*] interface A { iterable<M>; };",
      "[Exposed=*] interface A { iterable<M, long>; };", "[Exposed=*] interface A { async_iterable<M>; };",
      "[Exposed=*] interface A { async_iterable<long>(optional M value); };", "[Exposed=*] interface A { maplike<DOMString, M>; };",
      "[Exposed=*] interface A { readonly setlike<M>; };",
    ] {
    assert_false(
      check_interface_mixin_source("interface mixin M {};" + declaration),
    )
  }
}

///|
test "Interface mixin type checks include unused typedefs and cyclic type graphs" {
  for
    source in [
      "typedef M Alias;", "typedef M? Alias;", "typedef sequence<M> Alias;", "typedef record<DOMString, FrozenArray<M>> Alias;",
      "typedef (sequence<Loop> or M) Loop;",
    ] {
    assert_false(check_interface_mixin_source("interface mixin M {};" + source))
  }
}

///|
test "Mixin names do not hide same-named type definitions" {
  for
    declaration in [
      "[Exposed=*] interface M {};", "dictionary M {};", "enum M { \"value\" };",
      "callback M = undefined ();", "callback interface M { undefined run(); };",
      "typedef long M;",
    ] {
    let reference = "[Exposed=*] interface A { M run(); };"
    assert_true(
      check_interface_mixin_source(
        "interface mixin _M {};" + declaration + reference,
      ),
    )
    assert_true(
      check_interface_mixin_source(
        declaration + reference + "interface mixin _M {};",
      ),
    )
  }
  assert_false(
    check_interface_mixin_source(
      "interface mixin M {}; namespace M {}; [Exposed=*] interface A { M run(); };",
    ),
  )
  assert_true(
    check_interface_mixin_source(
      "interface mixin M { undefined run(long M); }; [Exposed=*] interface A {}; A includes M;",
    ),
  )
}
