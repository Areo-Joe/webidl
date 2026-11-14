///|
fn check_union_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Union constraints cover every type entry and typedef order" {
  for (prefix, suffix) in nullable_declaration_forms() {
    for
      (definitions, type_, valid) in [
        ("typedef any Anything;", "(Anything or long)", false),
        ("typedef any _Anything;", "(DOMString or _Anything)", false),
        ("typedef any Anything;", "((Anything or long) or boolean)", false),
        ("", "(long? or DOMString?)", false),
        ("", "(long? or (DOMString? or boolean))", false),
        ("", "((long or boolean)? or DOMString?)", false),
        ("typedef long? Maybe;", "(Maybe or _Maybe)", false),
        ("typedef (long? or DOMString) Value;", "(Value or Value)", false),
        (
          "typedef long? Maybe; typedef (Maybe or DOMString) Left; typedef (Maybe or boolean) Right;",
          "(Left or Right)", false,
        ),
        ("dictionary Options {};", "(long? or Options)", false),
        ("dictionary _Options {};", "(Options? or long)", false),
        (
          "dictionary Options {}; typedef Options Config; typedef long? Maybe;",
          "(Maybe or _Config)", false,
        ),
        ("dictionary Options {};", "((Options or long) or DOMString?)", false),
        (
          "typedef any Anything;", "(sequence<(Anything or long)> or boolean)", false,
        ),
        ("", "(long or DOMString)", true),
        ("", "(long? or DOMString)", true),
        ("", "(long or DOMString)?", true),
        ("dictionary Options {};", "(Options or DOMString)", true),
        ("dictionary Options {};", "(sequence<long?> or Options)", true),
        (
          "dictionary Options {}; typedef long? Maybe;", "(sequence<Maybe> or Options)",
          true,
        ),
        ("dictionary Options {};", "(sequence<Options> or long?)", true),
        (
          "dictionary Options {};", "(record<DOMString, Options> or long?)", true,
        ),
        ("typedef any Anything;", "(sequence<Anything> or long)", true),
        ("", "([Clamp] long? or DOMString)", true),
        ("", "([Clamp] long? or [Clamp] DOMString?)", false),
      ] {
      let declaration = prefix + "Promise<" + type_ + ">" + suffix
      for source in [definitions + declaration, declaration + definitions] {
        assert_eq(check_union_source(source), valid)
      }
    }
  }
}

///|
test "Union checks distinguish repeated references from recursive references" {
  for
    source in [
      "typedef (A or long?) A;", "typedef (A or A or long?) A;", "typedef (B or long) A; typedef (A or DOMString?) B;",
      "typedef any Anything; typedef (A or Anything) A;", "dictionary Options {}; typedef (A or Options) A; typedef (A or long?) Bad;",
      "typedef (long? or DOMString) Value; typedef (Value or Value or boolean) Bad;",
    ] {
    assert_false(check_union_source(source))
  }
  for
    source in [
      "typedef (A or long) A;", "typedef (B or long) A; typedef (A or DOMString) B;",
      "typedef (sequence<A> or long?) A;", "typedef long? Maybe; typedef (Maybe or sequence<Maybe>) Value;",
      "dictionary Options {}; typedef (A or Options) A;",
    ] {
    assert_true(check_union_source(source))
  }
}

///|
test "Nullable member count excludes the outer union marker and container elements" {
  for
    (source, expected) in [
      ("(long or DOMString)?", 0),
      ("(long? or DOMString)", 1),
      ("((long or boolean)? or DOMString)", 1),
      ("((long? or boolean)? or DOMString)", 2),
      ("(long? or DOMString?)", 2),
      ("(sequence<long?> or DOMString)", 0),
      ("(record<DOMString, long?> or boolean)", 0),
    ] {
    let (type_, rest) = @parser.Type::parse(
      @lexer.tokenize(source).exact_view(),
    ).unwrap()
    assert_true(rest is [])
    guard type_ is UnionType(union_type, _) else {
      fail("Expected a union type")
    }
    assert_eq(number_of_nullable_member_types(union_type, Map([])), expected)
  }
}

///|
test "Union checks inspect every member and definition" {
  for
    source in [
      "typedef any Anything; typedef (long or boolean or Anything) Bad;", "typedef long First; typedef (long? or DOMString?) Last;",
      "[Exposed=*] interface A { attribute long first; attribute (long? or DOMString?) last; };",
      "[Exposed=*] interface A {}; [Exposed=*] interface B { undefined use(long first, (long? or DOMString?) last); };",
      "dictionary Options {}; dictionary D { long first; (Options or long?) last; };",
      "typedef (long? or DOMString?) Value; [Exposed=*] namespace N { const Value VALUE = 0; };",
    ] {
    assert_false(check_union_source(source))
  }
}

///|
test "Union checks cover operation forms and every collection type slot" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A { static ", " use(); };"),
      ("[Exposed=*] interface A { static undefined use(", " value); };"),
      ("[Exposed=*] interface A { getter ", " get(DOMString name); };"),
      (
        "[Exposed=*] interface A { setter undefined set(DOMString name, ", " value); };",
      ),
      ("interface mixin M { ", " get(); };"),
      (
        "interface mixin M {}; partial interface mixin M { undefined use(", " value); };",
      ),
      ("namespace N { ", " get(); };"),
      ("namespace N {}; partial namespace N { undefined use(", " value); };"),
      ("[Exposed=*] interface A { iterable<", ", DOMString>; };"),
      ("[Exposed=*] interface A { async_iterable<", ", DOMString>; };"),
      ("[Exposed=*] interface A { maplike<DOMString, ", ">; };"),
      ("[Exposed=*] interface A { readonly maplike<", ", DOMString>; };"),
      (
        "[Exposed=*] interface A {}; partial interface A { readonly setlike<", ">; };",
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { async_iterable<long>(optional ",
        " value); };",
      ),
    ] {
    for
      (type_, valid) in [
        ("(Anything or long)", false),
        ("(long or double)", false),
        ("(long? or DOMString?)", false),
        ("(long? or Options)", false),
        ("(long? or DOMString)", true),
      ] {
      assert_eq(
        check_union_source(
          "dictionary Options {}; typedef any Anything;" +
          prefix +
          type_ +
          suffix,
        ),
        valid,
      )
    }
  }
}
