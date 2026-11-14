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
      "(ObservableArray<long> or DOMString)", "long?", "DOMString?",
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
