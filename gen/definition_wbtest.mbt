///|
test "Partial mixins require an original interface mixin definition" {
  for
    source in [
      "partial interface mixin M {};", "partial interface mixin _M { undefined run(); };",
      "interface mixin Other {}; partial interface mixin M {};", "partial interface mixin M {}; partial interface mixin M {};",
      "interface M {}; partial interface mixin M {};", "dictionary M {}; partial interface mixin M {};",
      "namespace M {}; partial interface mixin M {};", "callback interface M { undefined run(); }; partial interface mixin M {};",
      "typedef long M; partial interface mixin M {};",
    ] {
    let accepted = try parse_linked_definitions(source) catch {
      _ => false
    } noraise {
      _ => true
    }
    assert_false(accepted)
  }
}

///|
test "Partial mixin identifiers match original definitions regardless of order and escaping" {
  for original in ["interface mixin M {};", "interface mixin _M {};"] {
    for
      partial in [
        "partial interface mixin M { undefined run(); };", "partial interface mixin _M { undefined run(); };",
      ] {
      for source in [original + partial, partial + original] {
        guard parse_linked_definitions(source)
          is [InterfaceMixin(mixin_), PartialInterfaceMixin(partial)] else {
          fail("expected a mixin and its partial")
        }
        assert_eq(name_of_interface_mixin(mixin_), "M")
        assert_true(physical_equal(partial.host, mixin_))
        assert_eq(mixin_.partials.length(), 1)
        assert_true(physical_equal(mixin_.partials[0], partial))
      }
    }
  }
}

///|
test "Missing interface references raise validation errors during model construction" {
  for
    source in [
      "interface A : Missing {};", "interface A : _Missing {};", "interface A : B {}; interface B : Missing {};",
      "dictionary Missing {}; interface A : Missing {};", "callback interface Missing { undefined run(); }; interface A : Missing {};",
      "partial interface Missing {};", "partial interface _Missing { undefined run(); };",
      "dictionary Missing {}; partial interface Missing {};", "interface mixin Missing {}; partial interface Missing {};",
    ] {
    let accepted = try parse_linked_definitions(source) catch {
      _ => false
    } noraise {
      _ => true
    }
    assert_false(accepted)
  }
}

///|
test "interface inheritance is resolved after definitions are created" {
  let (definitions, rest) = @parser.parse(
    (try! @lexer.tokenize("interface Child : Parent {}; interface Parent {};")).exact_view(),
  )
  assert_true(rest is [])

  guard Definition::from_parser(definitions)
    is [Interface(child), Interface(parent)] else {
    fail("expected two interfaces")
  }

  assert_true(parent.inheritance is None)
  assert_true(
    child.inheritance is Some(inherited) &&
    name_of_interface(inherited) == name_of_interface(parent),
  )
}

///|
test "interface identifiers are normalized once" {
  let (definitions, rest) = @parser.parse(
    (try! @lexer.tokenize("interface _interface {};")).exact_view(),
  )
  assert_true(rest is [])

  guard Definition::from_parser(definitions) is [Interface(interface)] else {
    fail("expected one interface")
  }

  assert_eq(name_of_interface(interface), "interface")
}

///|
fn parse_linked_definitions(source : String) -> Array[Definition] raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  Definition::from_parser(definitions)
}

///|
test "interface partials are linked in declaration order" {
  let definitions = parse_linked_definitions(
    "partial interface _A { undefined first(); }; interface A {}; interface B {}; partial interface A { undefined second(); undefined third(); };",
  )
  guard definitions
    is [
      Interface(a),
      Interface(b),
      PartialInterface(first),
      PartialInterface(second),
    ] else {
    fail("expected interfaces and partials")
  }
  assert_eq(a.partials.map(p => p.members.length()), [1, 2])
  assert_eq(b.partials.length(), 0)
  assert_eq(first.host.partials.length(), 2)
  assert_eq(second.host.partials.length(), 2)
  assert_eq(a.partials[0].members[0].host.host.partials.length(), 2)
  // Both traversal paths must reach the same partial's member array.
  first.members.clear()
  assert_eq(a.partials[0].members.length(), 0)
  assert_eq(a.partials[1].members.length(), 2)
}

///|
test "mixin partials are linked in declaration order" {
  let definitions = parse_linked_definitions(
    "partial interface mixin _M { undefined first(); }; interface mixin M {}; interface mixin N {}; partial interface mixin M { undefined second(); undefined third(); };",
  )
  guard definitions
    is [
      InterfaceMixin(m),
      InterfaceMixin(n),
      PartialInterfaceMixin(first),
      PartialInterfaceMixin(second),
    ] else {
    fail("expected mixins and partials")
  }
  assert_eq(m.partials.map(p => p.members.length()), [1, 2])
  assert_eq(n.partials.length(), 0)
  assert_eq(first.host.partials.length(), 2)
  assert_eq(second.host.partials.length(), 2)
  assert_eq(m.partials[0].members[0].host.host.partials.length(), 2)
  first.members.clear()
  assert_eq(m.partials[0].members.length(), 0)
  assert_eq(m.partials[1].members.length(), 2)
}

///|
test "dictionary partials are linked in declaration order" {
  let definitions = parse_linked_definitions(
    "partial dictionary _D { long first; }; dictionary D {}; dictionary E {}; partial dictionary D { long second; long third; };",
  )
  guard definitions
    is [
      Dictionary(d),
      Dictionary(e),
      PartialDictionary(first),
      PartialDictionary(second),
    ] else {
    fail("expected dictionaries and partials")
  }
  assert_eq(d.partials.map(p => p.members.length()), [1, 2])
  assert_eq(e.partials.length(), 0)
  assert_eq(first.host.partials.length(), 2)
  assert_eq(second.host.partials.length(), 2)
  assert_eq(d.partials[0].members[0].host.host.partials.length(), 2)
  first.members.clear()
  assert_eq(d.partials[0].members.length(), 0)
  assert_eq(d.partials[1].members.length(), 2)
}

///|
test "namespace partials are linked in declaration order" {
  let definitions = parse_linked_definitions(
    "partial namespace _N { undefined first(); }; namespace N {}; namespace O {}; partial namespace N { undefined second(); undefined third(); };",
  )
  guard definitions
    is [
      Namespace(n),
      Namespace(o),
      PartialNamespace(first),
      PartialNamespace(second),
    ] else {
    fail("expected namespaces and partials")
  }
  assert_eq(n.partials.map(p => p.members.length()), [1, 2])
  assert_eq(o.partials.length(), 0)
  assert_eq(first.host.partials.length(), 2)
  assert_eq(second.host.partials.length(), 2)
  assert_eq(n.partials[0].members[0].host.host.partials.length(), 2)
  first.members.clear()
  assert_eq(n.partials[0].members.length(), 0)
  assert_eq(n.partials[1].members.length(), 2)
}
