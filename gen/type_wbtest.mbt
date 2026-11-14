///|
fn resolved_type_states(
  source : String,
  type_source : String,
) -> Array[(@parser.Type, Bool)] raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  let typedefs = Map([])
  for definition in Definition::from_parser(definitions) {
    if definition is Typedef(typedef_) {
      typedefs.set(strip_underscore(typedef_.identifier), typedef_)
    }
  }
  let (type_, rest) = @parser.Type::parse(
    @lexer.tokenize(type_source).exact_view(),
  ).unwrap()
  assert_true(rest is [])
  let states = iter_types_resolving_typedefs(type_, typedefs)
    .take(100)
    .collect()
  assert_true(states.length() < 100)
  states
}

///|
test "Typedef traversal distinguishes nullable reference states" {
  let states = resolved_type_states(
    "typedef ObservableArray<long> Items;", "(Items or Items? or Items or Items?)",
  )
  let arrays = states.filter_map(state => {
    if state.0 is SingleType(DistinguishableType(ObservableArray(_, _))) {
      Some(state.1)
    } else {
      None
    }
  })
  assert_eq(arrays, [false, true])
  for state in states {
    if state.0 is SingleType(DistinguishableType(PrimitiveType(_, _))) {
      assert_false(state.1)
    }
  }
}

///|
test "Typedef traversal terminates on cycles and still visits other branches" {
  for
    source in [
      "typedef (sequence<A> or Items?) A; typedef ObservableArray<long> Items;",
      "typedef sequence<B> A; typedef (sequence<A> or Items?) B; typedef ObservableArray<long> Items;",
      "typedef (sequence<_A> or _Items?) _A; typedef ObservableArray<long> _Items;",
    ] {
    let states = resolved_type_states(source, "A")
    assert_true(
      states.any(state => {
        state.0 is SingleType(DistinguishableType(ObservableArray(_, _))) &&
        state.1
      }),
    )
  }
  let states = resolved_type_states("typedef sequence<A> A;", "A?")
  assert_eq(states.length(), 4)
}

///|
test "Typedef traversal retains original type annotations and unresolved names" {
  let states = resolved_type_states(
    "typedef [Example] sequence<[Element] long?> Names;", "Names?",
  )
  assert_true(
    states[1].0 is SingleType(DistinguishableType(Sequence(inner, None))) &&
    inner.type_ is SingleType(DistinguishableType(PrimitiveType(_, Some))) &&
    inner.extended_attribute_list.iter().count() == 1,
  )
  assert_true(states[1].1)
  assert_true(states[2].1)
  let states = resolved_type_states("", "External?")
  assert_eq(states.length(), 1)
  assert_true(
    states[0].0 is SingleType(DistinguishableType(Identifier("External", Some))),
  )
  assert_true(states[0].1)
}
