///|
fn check_typedef_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Typedef cannot directly reference itself including escaped identifiers" {
  for
    source in [
      "typedef Self Self;", "typedef _Self Self;", "typedef Self _Self;", "typedef _Self _Self;",
      "typedef [Clamp] Self Self;",
    ] {
    assert_false(check_typedef_source(source))
  }
}

///|
test "Typedef cannot directly reference another typedef regardless of declaration order" {
  for target in ["Name", "_Name"] {
    for identifier in ["Name", "_Name"] {
      let original = "typedef DOMString " + identifier + ";"
      let alias_source = "typedef " + target + " Alias;"
      assert_false(check_typedef_source(original + alias_source))
      assert_false(check_typedef_source(alias_source + original))
    }
  }
  assert_false(check_typedef_source("typedef B A; typedef A B;"))
  assert_false(
    check_typedef_source(
      "typedef DOMString A; typedef long Unrelated; typedef A B;",
    ),
  )
}

///|
test "Typedef direct alias restriction allows builtin and other definition types" {
  for
    source in [
      "typedef DOMString Name;", "typedef unsigned long Count;", "typedef [Clamp] unsigned long Count;",
      "typedef DOMString? OptionalName;", "typedef sequence<DOMString> Names;", "typedef (DOMString or long) Value;",
      "[Exposed=*] interface Target {}; typedef Target Alias;", "typedef _Target Alias; [Exposed=*] interface Target {};",
      "enum Target { \"value\" }; typedef Target Alias;", "dictionary Target {}; typedef Target Alias;",
      "callback Target = undefined (); typedef Target Alias;", "typedef DOMString A; typedef long B;",
    ] {
    assert_true(check_typedef_source(source))
  }
}

///|
test "Typedef direct alias restriction does not traverse compound target types" {
  for
    source in [
      "typedef DOMString Name; typedef sequence<Name> Names;", "typedef DOMString Name; typedef (Name or long) Value;",
      "typedef DOMString Name; typedef FrozenArray<Name> Names;", "typedef DOMString Name; typedef record<DOMString, Name> Names;",
    ] {
    assert_true(check_typedef_source(source))
  }
}
