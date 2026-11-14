///|
fn check_observable_array_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Observable array types are permitted on interface attributes including partials and mixins" {
  for
    (prefix, suffix, forms) in [
      (
        "[Exposed=*] interface A {",
        "};",
        ["attribute", "readonly attribute", "inherit attribute"],
      ),
      (
        "[Exposed=*] interface A {}; partial interface A {",
        "};",
        ["attribute", "readonly attribute", "inherit attribute"],
      ),
      (
        "partial interface A {",
        "}; [Exposed=*] interface A {};",
        ["attribute", "readonly attribute"],
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
          "ObservableArray<long>", "Values", "_Values", "ObservableArray<long?>",
          "ObservableArray<([Clamp] long or DOMString)>",
        ] {
        let definitions = "typedef ObservableArray<long> _Values;"
        let declaration = prefix + form + " " + type_ + " value;" + suffix
        for source in [definitions + declaration, declaration + definitions] {
          assert_true(check_observable_array_source(source))
        }
      }
    }
  }
}

///|
test "Observable array types are rejected outside regular interface attributes" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A { static attribute ", " value; };"),
      ("[Exposed=*] interface A { static readonly attribute ", " value; };"),
      (
        "[Exposed=*] interface A {}; partial interface A { static attribute ", " value; };",
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { static readonly attribute ",
        " value; };",
      ),
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
        "ObservableArray<long>", "Values", "_Values", "sequence<Values>", "Promise<Values>",
        "(Values or DOMString)",
      ] {
      let definitions = "typedef ObservableArray<long> _Values;"
      let declaration = prefix + type_ + suffix
      for source in [definitions + declaration, declaration + definitions] {
        assert_false(check_observable_array_source(source))
      }
    }
    assert_true(check_observable_array_source(prefix + "long" + suffix))
  }
}

///|
test "Observable array types cannot occur within unions or container type parameters" {
  for
    type_ in [
      "(ObservableArray<long> or DOMString)", "(DOMString or Values)?", "((Values or DOMString) or boolean)",
      "sequence<Values>", "async_sequence<Values>", "record<DOMString, Values>",
      "Promise<Values>", "FrozenArray<Values>", "ObservableArray<Values>", "ObservableArray<sequence<Values>>",
    ] {
    for
      (prefix, suffix) in [
        ("typedef ", " Result;"),
        ("[Exposed=*] interface A { attribute ", " value; };"),
      ] {
      for
        source in [
          "typedef ObservableArray<long> Values;" + prefix + type_ + suffix,
          prefix + type_ + suffix + "typedef ObservableArray<long> Values;",
        ] {
        assert_false(check_observable_array_source(source))
      }
    }
  }
  assert_true(
    check_observable_array_source("typedef ObservableArray<long> Values;"),
  )
}

///|
test "Observable array checks distinguish typedef use positions and terminate on cycles" {
  for
    source in [
      "typedef ObservableArray<Value> Value;", "typedef ObservableArray<Value> Value; [Exposed=*] interface A { attribute Value value; };",
      "typedef ObservableArray<Other> Value; typedef sequence<Value> Other;", "typedef (Value or ObservableArray<long>) Value;",
      "typedef (Other or long) Value; typedef (Value or ObservableArray<long>) Other;",
      "typedef ObservableArray<long> Values; [Exposed=*] interface A { attribute Values first; undefined use(Values last); };",
      "typedef ObservableArray<long> Values; [Exposed=*] interface A { attribute Values first; attribute Promise<Values> last; };",
      "typedef ObservableArray<long> Values; [Exposed=*] interface A { attribute Promise<Values> first; attribute Values last; };",
    ] {
    assert_false(check_observable_array_source(source))
  }
  for
    source in [
      "typedef sequence<Value> Value;", "typedef (Other or long) Value; typedef (Value or DOMString) Other;",
      "typedef (Element or long) Element; [Exposed=*] interface A { attribute ObservableArray<Element> value; };",
    ] {
    assert_true(check_observable_array_source(source))
  }
}

///|
test "Observable array checks inspect optional variadic and later argument and member types" {
  for
    arguments in [
      "optional Values value", "optional Values? value = null", "Values... values",
      "long first, Values last", "long first, optional Values last",
    ] {
    assert_false(
      check_observable_array_source(
        "typedef ObservableArray<long> Values; [Exposed=*] interface A { undefined use(" +
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
      check_observable_array_source(
        "typedef ObservableArray<long> Values;" + source,
      ),
    )
  }
}

///|
test "Observable array elements reject forbidden types including nullable typedef targets" {
  let definitions = "dictionary _Options {}; typedef Options Config; typedef Config? MaybeConfig; typedef sequence<long> Seq; typedef Seq? MaybeSeq; typedef record<DOMString, long> Rec; typedef Rec? MaybeRec; typedef ObservableArray<long> Items; typedef long? MaybeLong; typedef (Options or DOMString) Choice;"
  for
    (element, valid) in [
      ("Options", false),
      ("_Options?", false),
      ("Config", false),
      ("MaybeConfig", false),
      ("sequence<long>", false),
      ("sequence<long>?", false),
      ("Seq", false),
      ("_MaybeSeq", false),
      ("record<DOMString, long>", false),
      ("record<DOMString, long>?", false),
      ("Rec", false),
      ("MaybeRec", false),
      ("ObservableArray<long>", false),
      ("Items", false),
      ("long", true),
      ("long?", true),
      ("MaybeLong", true),
      ("DOMString?", true),
      ("object?", true),
      ("Uint8Array", true),
      ("any", true),
      ("Promise<sequence<long>>", true),
      ("async_sequence<Options>", true),
      ("(long or DOMString)?", true),
      ("(Options or DOMString)", true),
      ("Choice", true),
      ("(sequence<long> or DOMString)", true),
    ] {
    for
      (prefix, suffix) in [
        ("typedef ObservableArray<", "> Target;"),
        ("[Exposed=*] interface A { attribute ObservableArray<", "> value; };"),
        (
          "[Exposed=*] interface A {}; partial interface A { readonly attribute ObservableArray<",
          "> value; };",
        ),
        (
          "interface mixin M { attribute ObservableArray<", "> value; }; [Exposed=*] interface A {}; A includes M;",
        ),
        (
          "interface mixin M {}; partial interface mixin M { readonly attribute ObservableArray<",
          "> value; }; [Exposed=*] interface A {}; A includes M;",
        ),
      ] {
      let declaration = prefix + element + suffix
      for source in [definitions + declaration, declaration + definitions] {
        assert_eq(check_observable_array_source(source), valid)
      }
    }
  }
}

///|
test "Observable array checks preserve nullable constraints and inspect every attribute" {
  for
    source in [
      "typedef ObservableArray<long>? Items;", "typedef ObservableArray<long> Items; typedef Items? MaybeItems;",
      "[Exposed=*] interface A { attribute ObservableArray<long>? value; };", "typedef any Anything; [Exposed=*] interface A { attribute ObservableArray<Anything?> value; };",
      "typedef Promise<long> Pending; [Exposed=*] interface A { attribute ObservableArray<Pending?> value; };",
      "dictionary D {}; [Exposed=*] interface A { attribute ObservableArray<(D or long)?> value; };",
      "typedef ObservableArray<long> Items; [Exposed=*] interface A { attribute Items first; static attribute Items last; };",
      "dictionary D {}; [Exposed=*] interface A { attribute ObservableArray<long> first; attribute ObservableArray<D> last; };",
      "dictionary D {}; [Exposed=*] interface A { attribute ObservableArray<long> first; }; partial interface A { attribute ObservableArray<D> last; };",
      "dictionary D {}; typedef ObservableArray<long> First; typedef ObservableArray<D> Last;",
      "typedef ObservableArray<long> Items; [Exposed=*] interface A { attribute FrozenArray<Items> value; };",
      "typedef FrozenArray<long> Items; [Exposed=*] interface A { attribute ObservableArray<Items> value; };",
    ] {
    assert_false(check_observable_array_source(source))
  }
}
