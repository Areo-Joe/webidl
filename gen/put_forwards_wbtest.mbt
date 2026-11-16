///|
test "PutForwards requires a read only regular interface attribute" {
  let target = "[Exposed=*] interface T { attribute long value; }; "
  for
    (declaration, expected) in [
      ("[PutForwards=value] attribute T value;", false),
      ("[PutForwards=value] readonly attribute T value;", true),
      ("[PutForwards=value] static attribute T value;", false),
      ("[PutForwards=value] static readonly attribute T value;", false),
      ("[PutForwards=value] inherit attribute T value;", false),
      ("[PutForwards=value] stringifier attribute T value;", false),
      ("[PutForwards=value] stringifier readonly attribute T value;", true),
      ("[PutForwards=value] readonly attribute long value;", false),
      ("[PutForwards=value] readonly attribute T? value;", false),
    ] {
    assert_eq(
      check_source(target + "[Exposed=*] interface A { " + declaration + " };"),
      expected,
    )
  }
  assert_false(
    check_source(
      "[Exposed=*] interface P { readonly attribute T value; }; " +
      target +
      "[Exposed=*] interface A : P { [PutForwards=value] inherit attribute T value; };",
    ),
  )
  assert_false(
    check_source(
      target +
      "namespace N { [PutForwards=value] readonly attribute T value; };",
    ),
  )
  assert_true(
    check_source(
      target +
      "typedef T Alias; [Exposed=*] interface A { [PutForwards=value] readonly attribute Alias value; };",
    ),
  )
}

///|
test "PutForwards requires the target attribute to exist" {
  assert_false(
    check_source(
      "[Exposed=*] interface T {}; [Exposed=*] interface A { [PutForwards=value] readonly attribute T value; };",
    ),
  )
  assert_true(
    check_source(
      "[Exposed=*] interface T {}; partial interface T { attribute long value; }; [Exposed=*] interface A { [PutForwards=value] readonly attribute T value; };",
    ),
  )
}

///|
test "PutForwards chains cannot cycle" {
  assert_true(
    check_source(
      "[Exposed=*] interface A { [PutForwards=y] readonly attribute B x; }; [Exposed=*] interface B { readonly attribute long y; };",
    ),
  )
  assert_true(
    check_source(
      "[Exposed=*] interface A { [PutForwards=y] readonly attribute B x; }; [Exposed=*] interface B { [PutForwards=z] readonly attribute C y; }; [Exposed=*] interface C { readonly attribute long z; };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { [PutForwards=x] readonly attribute A x; };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { [PutForwards=y] readonly attribute B x; }; [Exposed=*] interface B { [PutForwards=x] readonly attribute A y; };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { [PutForwards=y] readonly attribute B x; }; [Exposed=*] interface B { [PutForwards=z] readonly attribute C y; }; [Exposed=*] interface C {};",
    ),
  )
}

///|
test "PutForwards cannot combine with LegacyLenientSetter or Replaceable" {
  let target = "[Exposed=*] interface T { attribute long value; }; "
  for
    attribute in [
      "[PutForwards=value, LegacyLenientSetter]", "[LegacyLenientSetter, PutForwards=value]",
      "[PutForwards=value, Replaceable]", "[Replaceable, PutForwards=value]",
    ] {
    assert_false(
      check_source(
        target +
        "[Exposed=*] interface A { " +
        attribute +
        " readonly attribute T value; };",
      ),
    )
  }
  assert_true(
    check_source(
      target +
      "[Exposed=*] interface A { [PutForwards=value] readonly attribute T value; };",
    ),
  )
}

///|
test "PutForwards only recognizes the identifier form" {
  let target = "[Exposed=*] interface T { attribute long value; }; "
  for
    attribute in [
      "PutForwards", "PutForwards()", "PutForwards=(value)", "PutForwards=*",
    ] {
    assert_true(
      check_source(
        target +
        "[Exposed=*] interface A { [" +
        attribute +
        "] readonly attribute T value; };",
      ),
    )
  }
}
