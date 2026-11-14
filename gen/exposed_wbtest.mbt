///|
fn parse_exposure_definitions(input : String) -> Array[Definition] raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(input).exact_view())
  assert_true(rest is [])
  Definition::from_parser(definitions)
}

///|
test "explicit interface member exposure sets are not intersected with the interface" {
  let definitions = parse_exposure_definitions(
    "[Exposed=Window] interface A { [Exposed=Worker] undefined first(); }; partial interface A { [Exposed=Worker] undefined second(); };",
  )
  guard definitions[0] is Interface(interface) else {
    fail("expected interface")
  }
  for
    construct in [
      ExposedSetStruct::InterfaceMember(interface.members[0]),
      ExposedSetStruct::PartialInterfaceMember(interface.partials[0].members[0]),
    ] {
    guard exposure_set(construct, None) is List(names) else {
      fail("expected finite exposure set")
    }
    assert_eq(names.length(), 1)
    assert_true(names.contains("Worker"))
    assert_false(names.contains("Window"))
  }
}

///|
test "partial mixin exposure depends on the including interface" {
  let cases = [
    (
      "interface mixin M {}; partial interface mixin M { [Exposed=Window] undefined f(); };",
      false,
    ),
    (
      "interface mixin M {}; [Exposed=Window] partial interface mixin M { undefined f(); };",
      false,
    ),
    (
      "[Exposed=Window] interface mixin M {}; partial interface mixin M { undefined f(); };",
      false,
    ),
    (
      "interface mixin M {}; partial interface mixin M { undefined f(); };", true,
    ),
    (
      "interface mixin M {}; [Exposed=*] partial interface mixin M { undefined f(); };",
      true,
    ),
    (
      "[Exposed=(Window,Worker)] interface mixin M {}; partial interface mixin M { [Exposed=Window] undefined f(); };",
      false,
    ),
  ]
  for (mixin_source, exposed_in_worker) in cases {
    let definitions = parse_exposure_definitions(
      mixin_source +
      "[Exposed=Window] interface A {}; [Exposed=Worker] interface B {}; A includes M; B includes M;",
    )
    let partials = definitions.filter_map(x => {
      match x {
        PartialInterfaceMixin(partial) => Some(partial)
        _ => None
      }
    })
    let interfaces = definitions.filter_map(x => {
      match x {
        Interface(interface) => Some(interface)
        _ => None
      }
    })
    let mixin_member = ExposedSetStruct::PartialInterfaceMixinMember(
      partials[0].members[0],
    )
    guard exposure_set(mixin_member, Some(interfaces[0])) is List(window_set) else {
      fail("expected a finite exposure set")
    }
    assert_eq(window_set.length(), 1)
    assert_true(window_set.contains("Window"))
    guard exposure_set(mixin_member, Some(interfaces[1])) is List(worker_set) else {
      fail("expected a finite exposure set")
    }
    assert_eq(worker_set.length(), if exposed_in_worker { 1 } else { 0 })
    assert_eq(worker_set.contains("Worker"), exposed_in_worker)
  }
}
