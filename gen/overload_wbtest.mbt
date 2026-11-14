///|
fn parse_overload_arguments(source : String) -> @parser.ArgumentList raise {
  let (arguments, rest) = @parser.ArgumentList::parse(
    @lexer.tokenize(source).exact_view(),
  )
  assert_true(rest is [])
  arguments
}

///|
fn check_overload_sources(
  sources : Array[String],
  definition_source~ : String = "",
) -> Bool raise {
  let (parsed, rest) = @parser.parse(
    @lexer.tokenize(definition_source).exact_view(),
  )
  assert_true(rest is [])
  let typedefs = Map([])
  let definitions = Map([])
  for definition in Definition::from_parser(parsed) {
    if name_of_definition(definition) is Some(name) {
      definitions.set(name, definition)
    }
    if definition is Typedef(typedef_) {
      typedefs.set(strip_underscore(typedef_.identifier), typedef_)
    }
  }
  let callables = sources.mapi((i, source) => {
    (i, parse_overload_arguments(source))
  })
  try
    check_effective_overload_set(
      compute_effective_overload_set(callables, 0),
      typedefs,
      definitions,
    )
  catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Effective overload sets expand variadics and omit trailing optional arguments" {
  let sources = [
    "DOMString a", "Node a, DOMString b, double... c", "", "Event a, DOMString b, optional DOMString c, double... d",
  ]
  let callables = sources.mapi((i, source) => {
    (i, parse_overload_arguments(source))
  })
  let overloads = compute_effective_overload_set(callables, 4)
  let expected : Array[(Int32, Array[String], Array[Optionality])] = [
    (0, ["DOMString"], [Required]),
    (1, ["Node", "DOMString", "double"], [Required, Required, Variadic]),
    (
      1,
      ["Node", "DOMString", "double", "double"],
      [Required, Required, Variadic, Variadic],
    ),
    (1, ["Node", "DOMString"], [Required, Required]),
    (2, [], []),
    (
      3,
      ["Event", "DOMString", "DOMString", "double"],
      [Required, Required, Optional, Variadic],
    ),
    (3, ["Event", "DOMString", "DOMString"], [Required, Required, Optional]),
    (3, ["Event", "DOMString"], [Required, Required]),
  ]
  assert_eq(overloads.length(), expected.length())
  for i in 0..<expected.length() {
    let item = overloads[i]
    let (callable, types, optionality) = expected[i]
    assert_eq(item.callable, callable)
    assert_eq(item.types.length(), types.length())
    assert_eq(item.optionality, optionality)
    for j in 0..<types.length() {
      assert_true(
        same_type(
          item.types[j].type_,
          parse_distinguishable_type(types[j]),
          Map([]),
        ),
      )
    }
  }
  assert_eq(compute_effective_overload_set(callables, 0).length(), 8)
  assert_eq(compute_effective_overload_set(callables, 6).length(), 12)
  let empty : Array[(Int32, @parser.ArgumentList)] = []
  assert_true(compute_effective_overload_set(empty, 0).is_empty())
}

///|
test "Effective overload sets preserve callable identity and associated argument attributes" {
  let arguments = parse_overload_arguments(
    "[Clamp] long first, optional [EnforceRange] long last = 1",
  )
  let overloads = compute_effective_overload_set(
    [(0, arguments), (0, arguments)],
    0,
  )
  assert_eq(overloads.length(), 2)
  assert_eq(overloads[0].optionality, [Required, Optional])
  assert_eq(overloads[1].optionality, [Required])
  assert_true(
    same_type_attributes(
      overloads[0].types[0].extended_attributes,
      overloads[1].types[0].extended_attributes,
    ),
  )
  assert_eq(overloads[0].types[0].extended_attributes.length(), 1)
  assert_eq(overloads[0].types[1].extended_attributes.length(), 1)
  assert_false(
    same_type_attributes(
      overloads[0].types[0].extended_attributes,
      overloads[0].types[1].extended_attributes,
    ),
  )
}

///|
test "Effective overload sets require one index distinguishing every pair" {
  for
    (sources, expected) in [
      (["long value", "DOMString value"], true),
      (["DOMString value", "USVString value"], false),
      (["long value", "double value"], false),
      (["", ""], false),
      (["", "optional long value"], false),
      (["long... values", "DOMString... values"], false),
      (["long value", "DOMString value", "boolean value"], true),
      (["long a, long b", "DOMString a, long b", "long a, DOMString b"], false),
      (["long value", "long first, long second"], true),
      (["long first, long... rest", "DOMString value"], true),
      (["Promise<long> value", "DOMString value"], false),
      (["(long or boolean) value", "DOMString value"], true),
    ] {
    assert_eq(check_overload_sources(sources), expected)
  }
}

///|
test "Effective overload sets compare prefix types including nullable and annotated types" {
  let definitions = "typedef long Number; typedef [Clamp] long Clamped; typedef (long or boolean) Choice;"
  for
    (sources, expected) in [
      (["Number a, long b", "long a, DOMString b"], true),
      (["long a, long b", "double a, DOMString b"], false),
      (["long? a, long b", "long a, DOMString b"], false),
      (["[Clamp] long a, long b", "long a, DOMString b"], false),
      (["Clamped a, long b", "[Clamp] long a, DOMString b"], true),
      (["sequence<long?> a, long b", "sequence<long> a, DOMString b"], false),
      (["Choice a, long b", "(boolean or long) a, DOMString b"], true),
    ] {
    assert_eq(
      check_overload_sources(sources, definition_source=definitions),
      expected,
    )
  }
}

///|
test "Effective overload sets compare prefix optionality and select the lowest index" {
  let sources = ["long a, DOMString... b", "optional long a, boolean... b"]
  let callables = sources.mapi((i, source) => {
    (i, parse_overload_arguments(source))
  })
  let overloads = compute_effective_overload_set(callables, 0).filter(item => {
    item.types.length() == 2
  })
  assert_eq(distinguishing_argument_index(overloads, Map([]), Map([])), Some(1))
  let valid = try
    check_effective_overload_set(overloads, Map([]), Map([]))
  catch {
    _ => false
  } noraise {
    _ => true
  }
  assert_false(valid)
  let callables = [
    (0, parse_overload_arguments("long a, DOMString b")),
    (1, parse_overload_arguments("DOMString a, long b")),
  ]
  let overloads = compute_effective_overload_set(callables, 0)
  assert_eq(distinguishing_argument_index(overloads, Map([]), Map([])), Some(0))
  check_effective_overload_set(overloads, Map([]), Map([]))
}

///|
test "Effective overload sets reject bigint and numeric arguments at the distinguishing index" {
  for
    (sources, expected) in [
      (["bigint value", "long value"], false),
      (["bigint? value", "double value"], false),
      (["Big value", "Number value"], false),
      (["bigint value", "DOMString value"], true),
      (["long a, bigint b", "DOMString a, double b"], true),
    ] {
    assert_eq(
      check_overload_sources(
        sources,
        definition_source="typedef bigint Big; typedef [Clamp] long Number;",
      ),
      expected,
    )
  }
}

///|
test "Legacy factory function overloads are checked through doc and grouped by normalized name" {
  for
    (source, expected) in [
      (
        "[LegacyFactoryFunction=Create(long value), LegacyFactoryFunction=Create(DOMString value)] interface A {};",
        true,
      ),
      (
        "[LegacyFactoryFunction=Create(long value), LegacyFactoryFunction=_Create(double value)] interface A {};",
        false,
      ),
      (
        "[LegacyFactoryFunction=Create(long value), LegacyFactoryFunction=Other(double value)] interface A {};",
        true,
      ),
      (
        "[LegacyFactoryFunction=Create(), LegacyFactoryFunction=Create(optional long value)] interface A {};",
        false,
      ),
      (
        "[LegacyFactoryFunction=Create(bigint value), LegacyFactoryFunction=Create(long value)] interface A {};",
        false,
      ),
    ] {
    let (definitions, rest) = @parser.parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    let valid = try doc(definitions) catch {
      _ => false
    } noraise {
      _ => true
    }
    assert_eq(valid, expected)
  }
}
