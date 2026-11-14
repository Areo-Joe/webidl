///|
fn check_frozen_array_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Frozen array types are permitted on interface attributes including partials and mixins" {
  for
    (prefix, suffix, forms) in [
      (
        "[Exposed=*] interface A {",
        "};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute",
        ],
      ),
      (
        "[Exposed=*] interface A {}; partial interface A {",
        "};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute",
        ],
      ),
      (
        "partial interface A {",
        "}; [Exposed=*] interface A {};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
        ],
      ),
      (
        "interface mixin M {",
        "}; [Exposed=*] interface A {}; A includes M;",
        ["attribute", "readonly attribute"],
      ),
      (
        "interface mixin M {}; partial interface mixin M {",
        "}; [Exposed=*] interface A {}; A includes M;",
        ["attribute", "readonly attribute"],
      ),
      (
        "partial interface mixin M {",
        "}; interface mixin M {}; [Exposed=*] interface A {}; A includes M;",
        ["attribute", "readonly attribute"],
      ),
    ] {
    for form in forms {
      for
        type_ in [
          "FrozenArray<long>", "FrozenArray<long>?", "Values", "_Values?", "MaybeValues",
          "FrozenArray<long?>", "FrozenArray<sequence<long>>", "FrozenArray<record<DOMString, long>>",
          "FrozenArray<Options>", "FrozenArray<([Clamp] long or DOMString)>",
        ] {
        let definitions = "dictionary Options {}; typedef FrozenArray<long> _Values; typedef FrozenArray<long>? MaybeValues;"
        let declaration = attribute_declaration_source(
          prefix, suffix, form, type_,
        )
        for source in [definitions + declaration, declaration + definitions] {
          assert_true(check_frozen_array_source(source))
        }
      }
    }
  }
}

///|
test "Frozen array types are rejected at every non-interface-attribute use site" {
  for
    (prefix, suffix) in [
      ("namespace N { readonly attribute ", " value; };"),
      (
        "namespace N {}; partial namespace N { readonly attribute ", " value; };",
      ),
      (
        "partial namespace N { readonly attribute ", " value; }; namespace N {};",
      ),
      ("[Exposed=*] interface A { ", " get(); };"),
      ("[Exposed=*] interface A { static ", " get(); };"),
      ("[Exposed=*] interface A {}; partial interface A { ", " get(); };"),
      ("interface mixin M { ", " get(); };"),
      ("interface mixin M {}; partial interface mixin M { ", " get(); };"),
      ("namespace N { ", " get(); };"),
      ("namespace N {}; partial namespace N { ", " get(); };"),
      ("callback C = ", " ();"),
      ("callback interface C { ", " get(); };"),
      ("[Exposed=*] interface A { undefined use(", " value); };"),
      ("[Exposed=*] interface A { static undefined use(", " value); };"),
      (
        "[Exposed=*] interface A {}; partial interface A { undefined use(", " value); };",
      ),
      ("interface mixin M { undefined use(", " value); };"),
      (
        "interface mixin M {}; partial interface mixin M { undefined use(", " value); };",
      ),
      ("namespace N { undefined use(", " value); };"),
      ("namespace N {}; partial namespace N { undefined use(", " value); };"),
      ("callback C = undefined (", " value);"),
      ("callback interface C { undefined use(", " value); };"),
      ("[Exposed=*] interface A { constructor(", " value); };"),
      ("[Exposed=*, LegacyFactoryFunction=Create(", " value)] interface A {};"),
      ("dictionary D { ", " value; };"),
      ("dictionary D { required ", " value; };"),
      ("dictionary D {}; partial dictionary D { ", " value; };"),
      ("[Exposed=*] interface A { iterable<", ">; };"),
      ("[Exposed=*] interface A { iterable<", ", DOMString>; };"),
      ("[Exposed=*] interface A { iterable<DOMString, ", ">; };"),
      ("[Exposed=*] interface A { async_iterable<", ">; };"),
      ("[Exposed=*] interface A { async_iterable<", ", DOMString>; };"),
      ("[Exposed=*] interface A { async_iterable<DOMString, ", ">; };"),
      ("[Exposed=*] interface A { async_iterable<long>(", " value); };"),
      ("[Exposed=*] interface A { maplike<", ", DOMString>; };"),
      ("[Exposed=*] interface A { readonly maplike<DOMString, ", ">; };"),
      ("[Exposed=*] interface A { setlike<", ">; };"),
      ("[Exposed=*] interface A { readonly setlike<", ">; };"),
      ("[Exposed=*] interface A {}; partial interface A { iterable<", ">; };"),
      (
        "[Exposed=*] interface A {}; partial interface A { async_iterable<long>(",
        " value); };",
      ),
    ] {
    for
      type_ in [
        "FrozenArray<long>", "FrozenArray<long>?", "Values", "_Values?", "MaybeValues",
        "sequence<Values>", "Promise<Values>", "(Values or DOMString)",
      ] {
      let definitions = "typedef FrozenArray<long> _Values; typedef FrozenArray<long>? MaybeValues;"
      let declaration = prefix + type_ + suffix
      for source in [definitions + declaration, declaration + definitions] {
        assert_false(check_frozen_array_source(source))
      }
    }
    assert_true(check_frozen_array_source(prefix + "long" + suffix))
  }
}

///|
test "Frozen array types cannot occur within unions or container type parameters" {
  for
    type_ in [
      "(FrozenArray<long> or DOMString)", "(DOMString or Values)?", "((Values or DOMString) or boolean)",
      "sequence<Values>", "async_sequence<Values>", "record<DOMString, Values>",
      "Promise<Values>", "FrozenArray<Values>", "ObservableArray<Values>", "FrozenArray<sequence<Values>>",
    ] {
    for
      (prefix, suffix) in [
        ("typedef ", " Result;"),
        ("[Exposed=*] interface A { attribute ", " value; };"),
      ] {
      for
        source in [
          "typedef FrozenArray<long> Values;" + prefix + type_ + suffix,
          prefix + type_ + suffix + "typedef FrozenArray<long> Values;",
        ] {
        assert_false(check_frozen_array_source(source))
      }
    }
  }
  assert_true(
    check_frozen_array_source(
      "typedef FrozenArray<long> Values; typedef FrozenArray<long>? MaybeValues;",
    ),
  )
}

///|
test "Frozen array checks distinguish typedef use positions and terminate on cycles" {
  for
    source in [
      "typedef FrozenArray<Value> Value;", "typedef FrozenArray<Value> Value; [Exposed=*] interface A { attribute Value value; };",
      "typedef FrozenArray<Other> Value; typedef sequence<Value> Other;", "typedef (Value or FrozenArray<long>) Value;",
      "typedef (Other or long) Value; typedef (Value or FrozenArray<long>) Other;",
      "typedef FrozenArray<long> Values; [Exposed=*] interface A { attribute Values first; undefined use(Values last); };",
      "typedef FrozenArray<long> Values; [Exposed=*] interface A { attribute Values first; attribute Promise<Values> last; };",
      "typedef FrozenArray<long> Values; [Exposed=*] interface A { attribute Promise<Values> first; attribute Values last; };",
    ] {
    assert_false(check_frozen_array_source(source))
  }
  for
    source in [
      "typedef sequence<Value> Value;", "typedef (Other or long) Value; typedef (Value or DOMString) Other;",
      "typedef FrozenArray<sequence<Element>> Values; typedef sequence<Element> Element; [Exposed=*] interface A { attribute Values value; };",
    ] {
    assert_true(check_frozen_array_source(source))
  }
}

///|
test "Frozen array checks inspect optional variadic and later argument and member types" {
  for
    arguments in [
      "optional Values value", "optional Values? value = null", "Values... values",
      "long first, Values last", "long first, optional Values last",
    ] {
    assert_false(
      check_frozen_array_source(
        "typedef FrozenArray<long> Values; [Exposed=*] interface A { undefined use(" +
        arguments +
        "); };",
      ),
    )
  }
  for
    source in [
      "namespace N { readonly attribute long first; readonly attribute Values last; };",
      "namespace N {}; partial namespace N { readonly attribute long first; readonly attribute Values last; };",
      "dictionary D { long first; Values last; };", "dictionary D {}; partial dictionary D { long first; required Values last; };",
      "[Exposed=*] interface A { const Values value = 0; };", "[Exposed=*] interface A {}; partial interface A { const Values value = 0; };",
      "interface mixin M { const Values value = 0; };", "interface mixin M {}; partial interface mixin M { const Values value = 0; };",
      "namespace N { const Values value = 0; };", "namespace N {}; partial namespace N { const Values value = 0; };",
      "callback interface C { const Values value = 0; };",
    ] {
    assert_false(
      check_frozen_array_source("typedef FrozenArray<long> Values;" + source),
    )
  }
}
