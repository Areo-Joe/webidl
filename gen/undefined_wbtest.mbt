///|
fn check_undefined_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Undefined argument checks cover every argument list entry and typedef order" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A { undefined use(", "); };"),
      ("[Exposed=*] interface A { static undefined use(", "); };"),
      (
        "[Exposed=*] interface A {}; partial interface A { undefined use(", "); };",
      ),
      (
        "partial interface A { undefined use(", "); }; [Exposed=*] interface A {};",
      ),
      ("interface mixin M { undefined use(", "); };"),
      (
        "interface mixin M {}; partial interface mixin M { undefined use(", "); };",
      ),
      (
        "partial interface mixin M { undefined use(", "); }; interface mixin M {};",
      ),
      ("namespace N { undefined use(", "); };"),
      ("namespace N {}; partial namespace N { undefined use(", "); };"),
      ("partial namespace N { undefined use(", "); }; namespace N {};"),
      ("callback C = undefined (", ");"),
      ("callback interface C { undefined use(", "); };"),
      ("[Exposed=*] interface A { constructor(", "); };"),
      ("[Exposed=*, LegacyFactoryFunction=Create(", ")] interface A {};"),
      ("[Exposed=*] interface A { async_iterable<long>(", "); };"),
      ("[Exposed=*] interface A { async_iterable<DOMString, long>(", "); };"),
      (
        "[Exposed=*] interface A {}; partial interface A { async_iterable<long>(",
        "); };",
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { async_iterable<DOMString, long>(",
        "); };",
      ),
    ] {
    for
      (type_, valid) in [
        ("undefined", false),
        ("undefined?", false),
        ("Empty", false),
        ("_Empty", false),
        ("MaybeEmpty", false),
        ("WithUndefined", false),
        ("(undefined or long)", false),
        ("(long or Empty)?", false),
        ("((Empty or long) or DOMString)", false),
        ("(long or (DOMString or Empty))", false),
        ("long", true),
        ("long?", true),
        ("(long or DOMString)", true),
        ("sequence<Empty>", true),
        ("async_sequence<Empty>", true),
        ("record<DOMString, Empty>", true),
        ("Promise<Empty>", true),
        ("(sequence<Empty> or DOMString)", true),
      ] {
      let definitions = "typedef undefined _Empty; typedef undefined? MaybeEmpty; typedef (Empty or long) WithUndefined;"
      let declaration = prefix + type_ + " value" + suffix
      for source in [definitions + declaration, declaration + definitions] {
        assert_eq(check_undefined_source(source), valid)
      }
    }
    for
      arguments in [
        "optional undefined value", "optional undefined value = undefined", "undefined... values",
        "[Example] undefined value", "optional [Clamp] undefined value", "long first, undefined last",
      ] {
      assert_false(check_undefined_source(prefix + arguments + suffix))
    }
    for
      arguments in [
        "", "optional long value", "long... values", "long first, optional DOMString last",
      ] {
      assert_true(check_undefined_source(prefix + arguments + suffix))
    }
  }
}

///|
test "Undefined dictionary member checks cover required optional and partial declarations" {
  for
    (prefix, suffix) in [
      ("dictionary D {", "};"),
      ("dictionary D {}; partial dictionary D {", "};"),
      ("partial dictionary D {", "}; dictionary D {};"),
    ] {
    for required in ["", "required "] {
      for
        (type_, valid) in [
          ("undefined", false),
          ("undefined?", false),
          ("Empty", false),
          ("_Empty?", false),
          ("(Empty or long)", false),
          ("((long or Empty) or DOMString)", false),
          ("ValueUnion", false),
          ("long", true),
          ("long?", true),
          ("sequence<Empty>", true),
          ("record<DOMString, Empty>", true),
          ("Promise<(Empty or long)>", true),
          ("(sequence<Empty> or long)", true),
        ] {
        let definitions = "typedef undefined _Empty; typedef (Empty or DOMString) ValueUnion;"
        let declaration = prefix + required + type_ + " value;" + suffix
        for source in [definitions + declaration, declaration + definitions] {
          assert_eq(check_undefined_source(source), valid)
        }
      }
    }
    for
      member_ in [
        "undefined value = undefined;", "[Example] undefined value;", "required [Clamp] undefined value;",
        "long first; undefined last;",
      ] {
      assert_false(check_undefined_source(prefix + member_ + suffix))
    }
  }
}

///|
test "Undefined argument checks cover static and named and unnamed special operations" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
    ] {
    for
      operation in [
        "static undefined use(undefined value);", "getter undefined get(undefined name);",
        "getter undefined (undefined name);", "setter undefined set(DOMString name, undefined value);",
        "setter undefined (DOMString name, undefined value);", "deleter boolean remove(undefined name);",
        "deleter boolean (undefined name);",
      ] {
      assert_false(check_undefined_source(prefix + operation + suffix))
    }
  }
}

///|
test "Undefined checks terminate on typedef cycles and visit other union branches" {
  for
    definitions in [
      "typedef (Value or undefined) Value;", "typedef (undefined or Value) Value;",
      "typedef (Other or long) Value; typedef (Value or undefined) Other;", "typedef (Other or undefined) Value; typedef (Value or long) Other;",
      "typedef (sequence<Value> or undefined) Value;",
    ] {
    for
      declaration in [
        "[Exposed=*] interface A { undefined use(Value value); };", "dictionary D { Value value; };",
      ] {
      assert_false(check_undefined_source(definitions + declaration))
    }
  }
  for
    definitions in [
      "typedef (Value or long) Value;", "typedef (Other or long) Value; typedef (Value or DOMString) Other;",
      "typedef sequence<Value> Value;", "typedef (sequence<Other> or long) Value; typedef (Value or undefined) Other;",
    ] {
    for
      declaration in [
        "[Exposed=*] interface A { undefined use(Value value); };", "dictionary D { required Value value; };",
      ] {
      assert_true(check_undefined_source(definitions + declaration))
    }
  }
}

///|
test "Undefined checks inspect later arguments operations callbacks constructors and dictionary members" {
  for
    source in [
      "[Exposed=*] interface A { undefined use(long first, undefined last); };",
      "[Exposed=*] interface A { undefined first(); undefined last(undefined value); };",
      "[Exposed=*] interface A { undefined first(); }; partial interface A { undefined last(undefined value); };",
      "callback First = undefined (); callback Last = undefined (undefined value);",
      "[Exposed=*] interface A { constructor(); constructor(undefined value); };",
      "[Exposed=*, LegacyFactoryFunction=First(long value), LegacyFactoryFunction=Last(undefined value)] interface A {};",
      "dictionary D { long first; undefined last; };", "dictionary D { long first; }; partial dictionary D { undefined last; };",
    ] {
    assert_false(check_undefined_source(source))
  }
}

///|
test "Undefined types remain permitted outside argument and dictionary member types" {
  for
    source in [
      "typedef undefined Empty; typedef undefined? MaybeEmpty;", "[Exposed=*] interface A { undefined get(); attribute undefined value; static attribute undefined other; };",
      "callback C = undefined (); callback interface I { undefined get(); };", "typedef undefined Empty; [Exposed=*] interface A { Empty get(); };",
      "typedef (undefined or long) Value; [Exposed=*] interface A { Value get(); };",
      "[Exposed=*] interface A { attribute FrozenArray<undefined> values; };", "[Exposed=*] interface A { attribute ObservableArray<undefined> values; };",
      "[Exposed=*] interface A { iterable<undefined>; };", "[Exposed=*] interface A { async_iterable<undefined>; };",
      "[Exposed=*] interface A { maplike<DOMString, undefined>; };", "[Exposed=*] interface A { setlike<undefined>; };",
    ] {
    assert_true(check_undefined_source(source))
  }
}
