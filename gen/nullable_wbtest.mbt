///|
fn check_nullable_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
fn nullable_declaration_forms() -> Array[(String, String)] {
  [
    ("typedef ", " Result;"),
    ("[Exposed=*] interface A { attribute ", " value; };"),
    (
      "[Exposed=*] interface A {}; partial interface A { attribute ", " value; };",
    ),
    ("interface mixin M { attribute ", " value; };"),
    (
      "interface mixin M {}; partial interface mixin M { attribute ", " value; };",
    ),
    ("namespace N { readonly attribute ", " value; };"),
    ("namespace N {}; partial namespace N { readonly attribute ", " value; };"),
    ("[Exposed=*] interface A { ", " get(); };"),
    ("[Exposed=*] interface A { undefined use(", " value); };"),
    ("callback C = ", " ();"),
    ("callback C = undefined (", " value);"),
    ("callback interface C { ", " get(); };"),
    ("callback interface C { undefined use(", " value); };"),
    ("dictionary D { ", " value; };"),
    ("dictionary D { required ", " value; };"),
    ("dictionary D {}; partial dictionary D { ", " value; };"),
    ("[Exposed=*] interface A { constructor(", " value); };"),
    ("[Exposed=*, LegacyFactoryFunction=Create(", " value)] interface A {};"),
    ("[Exposed=*] interface A { iterable<", ">; };"),
    ("[Exposed=*] interface A { iterable<", ", DOMString>; };"),
    ("[Exposed=*] interface A { iterable<DOMString, ", ">; };"),
    ("[Exposed=*] interface A { async_iterable<", ">; };"),
    ("[Exposed=*] interface A { async_iterable<DOMString, ", ">; };"),
    ("[Exposed=*] interface A { async_iterable<long>(", " value); };"),
    ("[Exposed=*] interface A { maplike<", ", DOMString>; };"),
    ("[Exposed=*] interface A { readonly maplike<DOMString, ", ">; };"),
    ("[Exposed=*] interface A { setlike<", ">; };"),
    ("[Exposed=*] interface A { readonly setlike<", ">; };"),
  ]
}

///|
test "Nullable constraints cover every declaration entry and typedef order" {
  for (prefix, suffix) in nullable_declaration_forms() {
    for
      (definitions, type_, valid) in [
        ("typedef any Anything;", "Anything?", false),
        ("typedef Promise<long> ResultType;", "ResultType?", false),
        ("typedef long? Maybe;", "Maybe?", false),
        ("typedef sequence<long>? Maybe;", "Maybe?", false),
        ("typedef (long or DOMString)? Maybe;", "Maybe?", false),
        ("", "(DOMString? or long)?", false),
        ("", "((DOMString? or long) or boolean)?", false),
        ("", "((long or boolean)? or DOMString)?", false),
        ("", "([Example] long? or DOMString)?", false),
        ("typedef long? Maybe;", "(_Maybe or DOMString)?", false),
        ("typedef (long? or DOMString) Value;", "Value?", false),
        ("dictionary Options {};", "(Options or DOMString)?", false),
        ("dictionary _Options {};", "((Options or long) or DOMString)?", false),
        (
          "dictionary Options {}; typedef Options Config;", "(_Config or DOMString)?",
          false,
        ),
        (
          "dictionary Options {}; typedef (Options or long) Value;", "Value?", false,
        ),
        ("typedef any Anything;", "sequence<Anything?>", false),
        ("typedef Promise<long> ResultType;", "FrozenArray<ResultType?>", false),
        ("typedef long? Maybe;", "record<DOMString, Maybe?>", false),
        ("typedef any Anything;", "Promise<sequence<Anything>?>", true),
        ("typedef long? Maybe;", "Promise<sequence<Maybe>?>", true),
        ("", "Promise<(sequence<long?> or DOMString)?>", true),
        ("", "Promise<(sequence<record<DOMString, long?>> or boolean)?>", true),
        (
          "dictionary Options {};", "Promise<(sequence<Options> or DOMString)?>",
          true,
        ),
        (
          "dictionary Options {}; typedef sequence<Options> Configs;", "Promise<(Configs or DOMString)?>",
          true,
        ),
      ] {
      let declaration = prefix + type_ + suffix
      for source in [definitions + declaration, declaration + definitions] {
        assert_eq(check_nullable_source(source), valid)
      }
    }
  }
}

///|
test "Argument types reject nullable dictionaries across all argument list entry points" {
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
      ("namespace N { undefined use(", "); };"),
      ("namespace N {}; partial namespace N { undefined use(", "); };"),
      ("callback interface C { undefined use(", "); };"),
      ("callback C = undefined (", ");"),
      ("[Exposed=*] interface A { constructor(", "); };"),
      ("[Exposed=*, LegacyFactoryFunction=Create(", ")] interface A {};"),
      ("[Exposed=*] interface A { async_iterable<long>(", "); };"),
      ("[Exposed=*] interface A { async_iterable<DOMString, long>(", "); };"),
      (
        "[Exposed=*] interface A {}; partial interface A { async_iterable<long>(",
        "); };",
      ),
    ] {
    for
      (type_, valid) in [
        ("Options?", false),
        ("_Options?", false),
        ("Config?", false),
        ("_MaybeConfig", false),
        ("Options", true),
        ("Config", true),
        ("sequence<Options?>", true),
        ("sequence<MaybeConfig>", true),
        ("async_sequence<Options?>", true),
        ("record<DOMString, Options?>", true),
        ("(Options or DOMString)", true),
      ] {
      let declaration = prefix + "optional " + type_ + " value" + suffix
      let definitions = "dictionary _Options {}; typedef Options Config; typedef Config? MaybeConfig;"
      for source in [definitions + declaration, declaration + definitions] {
        assert_eq(check_nullable_source(source), valid)
      }
    }
  }
}

///|
test "Nullable dictionary argument checks cover required optional variadic and later arguments" {
  for
    arguments in [
      "Options? value", "[Example] Options? value", "optional Options? value", "optional [Example] Options? value",
      "optional Options? value = null", "Options?... values", "long first, Options? last",
      "MaybeConfig value",
    ] {
    assert_false(
      check_nullable_source(
        "dictionary Options {}; typedef Options? MaybeConfig; [Exposed=*] interface A { undefined use(" +
        arguments +
        "); };",
      ),
    )
  }
  assert_false(
    check_nullable_source(
      "dictionary Options {}; [Exposed=*] interface A { setter undefined set(DOMString name, Options? value); };",
    ),
  )
  assert_true(
    check_nullable_source(
      "dictionary Options {}; [Exposed=*] interface A { setter undefined set(DOMString name, Options value); };",
    ),
  )
}

///|
test "Dictionary member types reject nullable dictionaries including partials and defaults" {
  for
    (prefix, suffix) in [
      ("dictionary D {", "};"),
      ("dictionary D {}; partial dictionary D {", "};"),
      ("partial dictionary D {", "}; dictionary D {};"),
    ] {
    for
      (member_source, valid) in [
        ("Options? value;", false),
        ("_Config? value;", false),
        ("MaybeConfig value;", false),
        ("required Options? value;", false),
        ("required [Example] MaybeConfig value;", false),
        ("[Example] Options? value;", false),
        ("Options? value = null;", false),
        ("Options value;", true),
        ("required Config value;", true),
        ("sequence<Options?> value;", true),
        ("sequence<MaybeConfig> value;", true),
        ("async_sequence<Options?> value;", true),
        ("record<DOMString, Options?> value;", true),
        ("(Options or DOMString) value;", true),
      ] {
      let declaration = prefix + member_source + suffix
      let definitions = "dictionary Options {}; typedef _Options Config; typedef Options? MaybeConfig;"
      for source in [definitions + declaration, declaration + definitions] {
        assert_eq(check_nullable_source(source), valid)
      }
    }
  }
  assert_false(
    check_nullable_source(
      "dictionary Options {}; dictionary D { long first; Options? last; };",
    ),
  )
}

///|
test "Nullable dictionaries remain permitted outside argument and dictionary member types" {
  for
    source in [
      "dictionary Options {}; typedef Options? Maybe;", "dictionary Options {}; callback C = Options? ();",
      "dictionary Options {}; [Exposed=*] interface A { Options? get(); };", "dictionary Options {}; typedef sequence<Options?> Values;",
    ] {
    assert_true(check_nullable_source(source))
  }
}

///|
test "Nullable constraints follow aliases through repeated states and cycles" {
  for
    source in [
      "typedef A? A;", "typedef B? A; typedef long B; typedef (B? or A?) Value;",
      "typedef B? A; typedef long B; typedef (A? or B?) Value;", "typedef (sequence<A> or long?) A; typedef A? Bad;",
      "typedef (A or long?) A; typedef A? Bad;", "dictionary Options {}; typedef (A or Options) A; typedef A? Bad;",
      "typedef (B or long) A; typedef (A or DOMString?) B; typedef A? Bad;",
    ] {
    assert_false(check_nullable_source(source))
  }
  for
    source in [
      "typedef sequence<A> A; typedef A? Maybe;", "typedef (A or long) A; typedef A? Maybe;",
      "dictionary Options {}; typedef (A or sequence<Options>) A; typedef A? Maybe;",
      "typedef long? Maybe; typedef (Maybe or DOMString) Value;", "typedef sequence<long?> Values; typedef (Values or DOMString)? Maybe;",
      "dictionary Options {}; typedef Options Config; typedef (Config or DOMString) Value;",
    ] {
    assert_true(check_nullable_source(source))
  }
}

///|
test "Nullable observable array checks resolve typedefs at every declaration entry" {
  for (prefix, suffix) in nullable_declaration_forms() {
    for
      (type_, valid) in [
        ("Items?", false),
        ("_Items?", false),
        ("sequence<Items?>", false),
        ("(Items or Items?)", false),
        ("(Items? or Items)", false),
        ("Promise<sequence<Items>?>", true),
        ("Items", true),
      ] {
      if prefix == "typedef " && type_ == "Items" {
        continue
      }
      let declaration = prefix + type_ + suffix
      for
        source in [
          "typedef ObservableArray<long> Items; " + declaration,
          declaration + " typedef ObservableArray<long> _Items;",
        ] {
        assert_eq(check_nullable_source(source), valid)
      }
    }
  }
}

///|
test "Nullable checks follow compound typedef references without propagating nullability to elements" {
  for
    source in [
      "typedef ObservableArray<long> Items; typedef Items? MaybeItems;", "typedef ObservableArray<long> Items; typedef sequence<Items?> Bad;",
      "typedef sequence<Items?> Bad; typedef ObservableArray<long> Items;", "typedef ObservableArray<long> Items; typedef Items? MaybeItems; typedef FrozenArray<MaybeItems> Bad;",
    ] {
    assert_false(check_nullable_source(source))
  }
  for
    source in [
      "typedef ObservableArray<long> Items; typedef sequence<Items>? MaybeSequence;",
      "typedef ObservableArray<long> Items; typedef (sequence<Items> or DOMString)? MaybeUnion;",
      "typedef ObservableArray<long?> Items; typedef sequence<Items> Nested;", "typedef sequence<A> A;",
      "typedef sequence<B> A; typedef sequence<A> B;",
    ] {
    assert_true(check_nullable_source(source))
  }
  assert_false(
    check_nullable_source(
      "typedef (sequence<A> or Items?) A; typedef ObservableArray<long> Items;",
    ),
  )
}

///|
test "Legacy factory function arguments reject nullable observable arrays" {
  for
    arguments in [
      "ObservableArray<long>? items", "optional ObservableArray<long>? items", "optional ObservableArray<long>? items = null",
      "ObservableArray<long>?... items", "[Example] ObservableArray<long>? items",
      "optional [Example] ObservableArray<long>? items", "sequence<Promise<ObservableArray<long>?>> items",
      "long first, ObservableArray<long>? last",
    ] {
    assert_false(
      check_nullable_source(
        "[Exposed=*, LegacyFactoryFunction=Create(" +
        arguments +
        ")] interface A {};",
      ),
    )
  }
  for arguments in ["", "long value", "optional DOMString? text = null"] {
    assert_true(
      check_nullable_source(
        "[Exposed=*, LegacyFactoryFunction=Create(" +
        arguments +
        ")] interface A {};",
      ),
    )
  }
}

///|
test "Nullable checks inspect every legacy factory function" {
  assert_false(
    check_nullable_source(
      "[Exposed=*, LegacyFactoryFunction=First(long value), LegacyFactoryFunction=Last(ObservableArray<long>? items)] interface A {};",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A {}; [Exposed=*, LegacyFactoryFunction=Create(ObservableArray<long>? items)] interface B {};",
    ),
  )
}

///|
test "Typedef targets reject nullable observable arrays at every nesting level" {
  for
    type_ in [
      "ObservableArray<long>?", "[Example] ObservableArray<long>?", "sequence<ObservableArray<long>?>",
      "async_sequence<ObservableArray<long>?>", "FrozenArray<ObservableArray<long>?>",
      "ObservableArray<ObservableArray<long>?>", "record<DOMString, ObservableArray<long>?>",
      "Promise<ObservableArray<long>?>", "(ObservableArray<long>? or DOMString)",
      "(DOMString or ObservableArray<long>?)", "(DOMString or long or ObservableArray<long>?)",
      "((ObservableArray<long>? or long) or DOMString)", "sequence<Promise<record<DOMString, ObservableArray<long>?>>>",
    ] {
    assert_false(check_nullable_source("typedef " + type_ + " Target;"))
  }
}

///|
test "Nullable observable array checks distinguish array and element nullability" {
  for
    type_ in [
      "ObservableArray<long>", "ObservableArray<long?>", "ObservableArray<DOMString?>",
      "sequence<ObservableArray<long>>?", "FrozenArray<ObservableArray<long?>>",
      "record<DOMString, ObservableArray<long?>>", "Promise<ObservableArray<long?>>",
      "(sequence<ObservableArray<long>> or DOMString)", "long?", "DOMString?",
    ] {
    assert_true(check_nullable_source("typedef " + type_ + " Target;"))
  }
}

///|
test "Nullable observable array checks inspect every typedef target" {
  assert_false(
    check_nullable_source(
      "typedef long First; typedef ObservableArray<long>? Last;",
    ),
  )
  assert_false(
    check_nullable_source(
      "typedef ObservableArray<long>? First; typedef long Last;",
    ),
  )
  assert_false(check_nullable_source("typedef ObservableArray<long>? _Target;"))
}

///|
test "Attribute nullable observable array checks cover every declaration and attribute form" {
  for
    (prefix, suffix, forms) in [
      (
        "[Exposed=*] interface A {",
        "};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "[Exposed=*] interface A {}; partial interface A {",
        "};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "partial interface A {",
        "}; [Exposed=*] interface A {};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "interface mixin M {",
        "};",
        [
          "attribute", "readonly attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "interface mixin M {}; partial interface mixin M {",
        "};",
        [
          "attribute", "readonly attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "partial interface mixin M {",
        "}; interface mixin M {};",
        [
          "attribute", "readonly attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      ("namespace N {", "};", ["readonly attribute"]),
      ("namespace N {}; partial namespace N {", "};", ["readonly attribute"]),
      ("partial namespace N {", "}; namespace N {};", ["readonly attribute"]),
    ] {
    for form in forms {
      assert_false(
        check_nullable_source(
          prefix + " " + form + " ObservableArray<long>? items; " + suffix,
        ),
      )
      assert_true(
        check_nullable_source(
          prefix + " " + form + " DOMString text; " + suffix,
        ),
      )
    }
  }
}

///|
test "Attribute checks visit nested types and distinguish element nullability" {
  for
    (type_, valid) in [
      ("ObservableArray<long>?", false),
      ("FrozenArray<ObservableArray<long>?>", false),
      ("sequence<ObservableArray<long>?>", false),
      ("async_sequence<ObservableArray<long>?>", false),
      ("record<DOMString, ObservableArray<long>?>", false),
      ("Promise<ObservableArray<long>?>", false),
      ("(DOMString or ObservableArray<long>?)", false),
      ("((long or ObservableArray<long>?) or DOMString)", false),
      ("[Example] ObservableArray<long>?", false),
      ("ObservableArray<long>", true),
      ("ObservableArray<long?>", true),
      ("DOMString?", true),
    ] {
    assert_eq(
      check_nullable_source(
        "[Exposed=*] interface A { attribute " + type_ + " items; };",
      ),
      valid,
    )
  }
}

///|
test "Nullable observable array checks inspect every attribute" {
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { attribute DOMString first; attribute ObservableArray<long>? last; };",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { attribute DOMString first; }; partial interface A { attribute ObservableArray<long>? last; };",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { attribute ObservableArray<long>? _items; };",
    ),
  )
}

///|
test "Operation return checks cover every declaration location" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
      ("interface mixin M {", "};"),
      ("interface mixin M {}; partial interface mixin M {", "};"),
      ("partial interface mixin M {", "}; interface mixin M {};"),
      ("namespace N {", "};"),
      ("namespace N {}; partial namespace N {", "};"),
      ("partial namespace N {", "}; namespace N {};"),
      ("callback interface C {", "};"),
    ] {
    for
      (type_, valid) in [
        ("ObservableArray<long>?", false),
        ("FrozenArray<ObservableArray<long>?>", false),
        ("sequence<ObservableArray<long>?>", false),
        ("async_sequence<ObservableArray<long>?>", false),
        ("record<DOMString, ObservableArray<long>?>", false),
        ("Promise<ObservableArray<long>?>", false),
        ("(DOMString or ObservableArray<long>?)", false),
        ("((long or ObservableArray<long>?) or DOMString)", false),
        ("ObservableArray<long>", true),
        ("ObservableArray<long?>", true),
        ("long?", true),
        ("undefined", true),
      ] {
      assert_eq(
        check_nullable_source(prefix + " " + type_ + " items(); " + suffix),
        valid,
      )
    }
  }
}

///|
test "Operation return checks cover regular static and named or unnamed special operations" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
    ] {
    for
      (special, rest, valid_type) in [
        ("", "items();", "long"),
        ("static ", "items();", "long"),
        ("getter ", "items(DOMString name);", "long"),
        ("getter ", "(DOMString name);", "long"),
        ("setter ", "items(DOMString name, long value);", "undefined"),
        ("setter ", "(DOMString name, long value);", "undefined"),
        ("deleter ", "items(DOMString name);", "boolean"),
        ("deleter ", "(DOMString name);", "boolean"),
      ] {
      assert_false(
        check_nullable_source(
          prefix +
          " " +
          special +
          "ObservableArray<long>? " +
          rest +
          " " +
          suffix,
        ),
      )
      assert_true(
        check_nullable_source(
          prefix + " " + special + valid_type + " " + rest + " " + suffix,
        ),
      )
    }
  }
}

///|
test "Nullable observable array checks inspect every operation return type" {
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { long first(); ObservableArray<long>? last(); };",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { long first(); }; partial interface A { ObservableArray<long>? last(); };",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { ObservableArray<long>? _items(); };",
    ),
  )
}

///|
test "Callback return checks visit nested types and distinguish element nullability" {
  for
    (type_, valid) in [
      ("ObservableArray<long>?", false),
      ("sequence<ObservableArray<long>?>", false),
      ("async_sequence<ObservableArray<long>?>", false),
      ("FrozenArray<ObservableArray<long>?>", false),
      ("record<DOMString, ObservableArray<long>?>", false),
      ("Promise<ObservableArray<long>?>", false),
      ("(DOMString or ObservableArray<long>?)", false),
      ("((long or ObservableArray<long>?) or DOMString)", false),
      ("sequence<Promise<record<DOMString, ObservableArray<long>?>>>", false),
      ("ObservableArray<long>", true),
      ("ObservableArray<long?>", true),
      ("Promise<ObservableArray<long?>>", true),
      ("DOMString?", true),
      ("undefined", true),
    ] {
    assert_eq(
      check_nullable_source("callback GetItems = " + type_ + " ();"),
      valid,
    )
  }
}

///|
test "Nullable observable array checks inspect every callback return type" {
  assert_false(
    check_nullable_source(
      "callback First = long (); callback Last = ObservableArray<long>? ();",
    ),
  )
  assert_false(
    check_nullable_source(
      "callback First = ObservableArray<long>? (); callback Last = long ();",
    ),
  )
  assert_false(
    check_nullable_source("callback _GetItems = ObservableArray<long>? ();"),
  )
  assert_false(
    check_nullable_source(
      "[Example] callback GetItems = ObservableArray<long>? (long count);",
    ),
  )
  assert_true(
    check_nullable_source(
      "callback First = long (); callback Last = ObservableArray<long?> (optional long count = 0);",
    ),
  )
}

///|
test "Dictionary member checks cover required optional and partial declarations" {
  for
    (prefix, suffix) in [
      ("dictionary Options {", "};"),
      ("dictionary Options {}; partial dictionary Options {", "};"),
      ("partial dictionary Options {", "}; dictionary Options {};"),
    ] {
    for required in ["", "required "] {
      for
        (type_, valid) in [
          ("ObservableArray<long>?", false),
          ("sequence<ObservableArray<long>?>", false),
          ("async_sequence<ObservableArray<long>?>", false),
          ("FrozenArray<ObservableArray<long>?>", false),
          ("record<DOMString, ObservableArray<long>?>", false),
          ("Promise<ObservableArray<long>?>", false),
          ("(DOMString or ObservableArray<long>?)", false),
          ("((long or ObservableArray<long>?) or DOMString)", false),
          ("ObservableArray<long>", true),
          ("ObservableArray<long?>", true),
          ("DOMString?", true),
        ] {
        assert_eq(
          check_nullable_source(
            prefix + " " + required + type_ + " items; " + suffix,
          ),
          valid,
        )
      }
      assert_false(
        check_nullable_source(
          prefix +
          " [Example] " +
          required +
          "ObservableArray<long>? items; " +
          suffix,
        ),
      )
    }
  }
}

///|
test "Dictionary member checks retain default values and type extended attributes" {
  assert_false(
    check_nullable_source(
      "dictionary Options { ObservableArray<long>? items = null; };",
    ),
  )
  assert_false(
    check_nullable_source(
      "dictionary Options { required [Example] ObservableArray<long>? items; };",
    ),
  )
  assert_true(
    check_nullable_source(
      "dictionary Options { DOMString? text = null; required ObservableArray<[Clamp] long?> items; };",
    ),
  )
}

///|
test "Nullable observable array checks inspect every dictionary member" {
  assert_false(
    check_nullable_source(
      "dictionary Options { long first; ObservableArray<long>? last; };",
    ),
  )
  assert_false(
    check_nullable_source(
      "dictionary Options { long first; }; partial dictionary Options { ObservableArray<long>? last; };",
    ),
  )
  assert_false(
    check_nullable_source(
      "dictionary Options { ObservableArray<long>? _items; };",
    ),
  )
}

///|
test "Operation and callback argument checks cover declaration locations and argument forms" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A { undefined use(", "); };"),
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
      ("callback interface C { undefined use(", "); };"),
      ("callback Use = undefined (", ");"),
    ] {
    for
      (argument, valid) in [
        ("ObservableArray<long>? items", false),
        ("optional ObservableArray<long>? items", false),
        ("optional ObservableArray<long>? items = null", false),
        ("ObservableArray<long>?... items", false),
        ("[Example] ObservableArray<long>? items", false),
        ("optional [Example] ObservableArray<long>? items", false),
        ("sequence<ObservableArray<long>?> items", false),
        ("async_sequence<ObservableArray<long>?> items", false),
        ("FrozenArray<ObservableArray<long>?> items", false),
        ("record<DOMString, ObservableArray<long>?> items", false),
        ("Promise<ObservableArray<long>?> items", false),
        ("(DOMString or ObservableArray<long>?) items", false),
        ("ObservableArray<long> items", true),
        ("ObservableArray<long?> items", true),
        ("optional DOMString? text = null", true),
        ("long... values", true),
        ("", true),
      ] {
      assert_eq(check_nullable_source(prefix + argument + suffix), valid)
    }
  }
}

///|
test "Argument checks cover static and named or unnamed special operations" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
    ] {
    for
      (operation, argument_prefix) in [
        ("static undefined use", ""),
        ("getter long item", ""),
        ("getter long ", ""),
        ("setter undefined item", "DOMString name, "),
        ("setter undefined ", "DOMString name, "),
        ("deleter boolean item", ""),
        ("deleter boolean ", ""),
      ] {
      assert_false(
        check_nullable_source(
          prefix +
          " " +
          operation +
          "(" +
          argument_prefix +
          "ObservableArray<long>? items); " +
          suffix,
        ),
      )
    }
  }
}

///|
test "Argument checks inspect every argument and every operation or callback" {
  for
    source in [
      "[Exposed=*] interface A { undefined use(long first, ObservableArray<long>? last); };",
      "[Exposed=*] interface A { undefined first(long value); undefined last(ObservableArray<long>? value); };",
      "[Exposed=*] interface A { undefined first(); }; partial interface A { undefined last(ObservableArray<long>? value); };",
      "callback Use = undefined (long first, ObservableArray<long>? last);", "callback First = undefined (); callback Last = undefined (ObservableArray<long>? value);",
      "callback Use = undefined (ObservableArray<long>? _items);",
    ] {
    assert_false(check_nullable_source(source))
  }
}

///|
test "Constructor argument checks cover argument forms and nested types" {
  for
    (arguments, valid) in [
      ("ObservableArray<long>? items", false),
      ("optional ObservableArray<long>? items", false),
      ("optional ObservableArray<long>? items = null", false),
      ("ObservableArray<long>?... items", false),
      ("[Example] ObservableArray<long>? items", false),
      ("optional [Example] ObservableArray<long>? items", false),
      ("sequence<ObservableArray<long>?> items", false),
      ("Promise<record<DOMString, ObservableArray<long>?>> items", false),
      ("long first, ObservableArray<long>? last", false),
      ("ObservableArray<long> items", true),
      ("ObservableArray<long?> items", true),
      ("optional DOMString? text = null", true),
      ("long... values", true),
      ("", true),
    ] {
    assert_eq(
      check_nullable_source(
        "[Exposed=*] interface A { constructor(" + arguments + "); };",
      ),
      valid,
    )
  }
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { constructor(); constructor(ObservableArray<long>? items); };",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A {}; [Exposed=*] interface B { constructor(ObservableArray<long>? items); };",
    ),
  )
}

///|
test "Collection type checks cover every type slot and partial declaration" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
    ] {
    for
      (start, end) in [
        ("iterable<", ">;"),
        ("iterable<", ", DOMString>;"),
        ("iterable<DOMString, ", ">;"),
        ("async_iterable<", ">;"),
        ("async_iterable<", ", DOMString>;"),
        ("async_iterable<DOMString, ", ">;"),
        ("maplike<", ", DOMString>;"),
        ("maplike<DOMString, ", ">;"),
        ("readonly maplike<", ", DOMString>;"),
        ("readonly maplike<DOMString, ", ">;"),
        ("setlike<", ">;"),
        ("readonly setlike<", ">;"),
      ] {
      for
        (type_, valid) in [
          ("ObservableArray<long>?", false),
          ("[Example] ObservableArray<long>?", false),
          ("sequence<ObservableArray<long>?>", false),
          ("async_sequence<ObservableArray<long>?>", false),
          ("FrozenArray<ObservableArray<long>?>", false),
          ("record<DOMString, ObservableArray<long>?>", false),
          ("Promise<ObservableArray<long>?>", false),
          ("(DOMString or ObservableArray<long>?)", false),
          ("ObservableArray<long>", true),
          ("ObservableArray<long?>", true),
          ("DOMString", true),
        ] {
        assert_eq(
          check_nullable_source(
            prefix + " " + start + type_ + end + " " + suffix,
          ),
          valid,
        )
      }
    }
  }
}

///|
test "Async iterable argument checks cover both iterable forms and partial declarations" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
    ] {
    for iterable in ["async_iterable<long>", "async_iterable<DOMString, long>"] {
      for
        (arguments, valid) in [
          ("ObservableArray<long>? items", false),
          ("optional ObservableArray<long>? items", false),
          ("optional ObservableArray<long>? items = null", false),
          ("ObservableArray<long>?... items", false),
          ("[Example] ObservableArray<long>? items", false),
          ("optional [Example] ObservableArray<long>? items", false),
          ("sequence<ObservableArray<long>?> items", false),
          ("Promise<record<DOMString, ObservableArray<long>?>> items", false),
          ("long first, ObservableArray<long>? last", false),
          ("ObservableArray<long> items", true),
          ("ObservableArray<long?> items", true),
          ("optional DOMString? text = null", true),
          ("long... values", true),
          ("", true),
        ] {
        assert_eq(
          check_nullable_source(
            prefix + " " + iterable + "(" + arguments + "); " + suffix,
          ),
          valid,
        )
      }
    }
  }
}

///|
test "Remaining interface member checks inspect every definition and member" {
  for
    body in [
      "iterable<ObservableArray<long>?>;", "async_iterable<ObservableArray<long>?>;",
      "async_iterable<long>(ObservableArray<long>? items);", "maplike<DOMString, ObservableArray<long>?>;",
      "readonly maplike<ObservableArray<long>?, DOMString>;", "setlike<ObservableArray<long>?>;",
      "readonly setlike<ObservableArray<long>?>;",
    ] {
    assert_false(
      check_nullable_source(
        "[Exposed=*] interface A { attribute long first; " + body + " };",
      ),
    )
    assert_false(
      check_nullable_source(
        "[Exposed=*] interface A {}; [Exposed=*] interface B { " + body + " };",
      ),
    )
    assert_false(
      check_nullable_source(
        "[Exposed=*] interface A {}; partial interface A { attribute long first; " +
        body +
        " };",
      ),
    )
  }
}
