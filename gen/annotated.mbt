///|
/// The following extended attributes are applicable to types:
/// [AllowResizable], [AllowShared], [Clamp], [EnforceRange], and [LegacyNullToEmptyString].
fn is_extended_attribute_applicable_to_types(
  attr : @parser.ExtendedAttribute,
) -> Bool {
  let name = match attr {
    NoArgs(attr) => attr.identifier
    ArgList(attr) => attr.identifier
    NamedArgList(attr) => attr.identifier
    Ident(attr) => attr.identifier
    String(attr) => attr.identifier
    Integer(attr) => attr.identifier
    Decimal(attr) => attr.identifier
    IntegerList(attr) => attr.identifier
    IdentList(attr) => attr.identifier
    Wildcard(attr) => attr.identifier
  }
  name
  is ("AllowResizable"
  | "AllowShared"
  | "Clamp"
  | "EnforceRange"
  | "LegacyNullToEmptyString")
}

///|
fn same_extended_attribute(
  left : @parser.ExtendedAttribute,
  right : @parser.ExtendedAttribute,
) -> Bool {
  match (left, right) {
    (NoArgs(left), NoArgs(right)) => left.identifier == right.identifier
    _ => physical_equal(left, right)
  }
}

///|
fn same_type_attributes(
  left : Array[@parser.ExtendedAttribute],
  right : Array[@parser.ExtendedAttribute],
) -> Bool {
  left.all(left => right.any(right => same_extended_attribute(left, right))) &&
  right.all(right => left.any(left => same_extended_attribute(left, right)))
}

///|
fn append_type_extended_attributes(
  attributes : Array[@parser.ExtendedAttribute],
  additional : Iter[@parser.ExtendedAttribute],
) -> Unit {
  for attr in additional {
    if !attributes.any(existing => same_extended_attribute(existing, attr)) {
      attributes.push(attr)
    }
  }
}

///|
/// If type is a typedef, append the extended attributes associated with the
/// type being given a new name to extended attributes.
fn resolve_type_with_extended_attributes(
  type_ : @parser.Type,
  attributes : Array[@parser.ExtendedAttribute],
  typedefs : Map[StringView, TypeDef],
) -> (@parser.Type, Bool, Array[@parser.ExtendedAttribute]) {
  let mut current = type_
  let mut nullable = false
  let associated_attributes = []
  append_type_extended_attributes(associated_attributes, attributes.iter())
  let attributes = associated_attributes
  let visited : Set[StringView] = Set([])
  while current is SingleType(DistinguishableType(Identifier(name, _))) {
    nullable = nullable || is_nullable_type(current)
    let name = strip_underscore(name)
    guard typedefs.get(name) is Some(target) && !visited.contains(name) else {
      break
    }
    visited.add(name)
    append_type_extended_attributes(
      attributes,
      target.type_with_extended_attributes.extended_attribute_list.iter(),
    )
    current = target.type_with_extended_attributes.type_
  }
  (current, nullable || is_nullable_type(current), attributes)
}

///|
/// If type is a member type of a union type U, append
/// each of the extended attributes associated with U to extended attributes.
fn union_member_types_with_extended_attributes(
  union_type : @parser.UnionType,
  inherited_attributes : Array[@parser.ExtendedAttribute],
) -> Iter[(@parser.Type, Array[@parser.ExtendedAttribute])] {
  union_type
  .iter_member_types()
  .zip(union_type.iter())
  .map(pair => {
    let (type_, union_member) = pair
    let attributes = []
    if union_member
      is DistinguishableTypeWithExtendedAttributeList(_, extended_attributes) {
      append_type_extended_attributes(attributes, extended_attributes.iter())
    }
    append_type_extended_attributes(attributes, inherited_attributes.iter())
    (type_, attributes)
  })
}

///|
fn iter_types_with_extended_attributes(
  type_ : @parser.Type,
  attributes : Array[@parser.ExtendedAttribute],
  typedefs : Map[StringView, TypeDef],
) -> Iter[(@parser.Type, Array[@parser.ExtendedAttribute])] {
  let pending = [(type_, attributes)]
  let visited : Array[(@parser.Type, Array[@parser.ExtendedAttribute])] = []
  Iter::new(fn() {
    guard pending.pop() is Some((type_, attributes)) else { return None }
    let (type_, _, attributes) = resolve_type_with_extended_attributes(
      type_, attributes, typedefs,
    )
    if !visited.any(previous => {
        physical_equal(previous.0, type_) &&
        previous.1.length() == attributes.length() &&
        previous.1
        .iter()
        .zip(attributes.iter())
        .all(pair => same_extended_attribute(pair.0, pair.1))
      }) {
      visited.push((type_, attributes))
      match type_ {
        UnionType(union_type, _) => {
          let members = union_member_types_with_extended_attributes(
            union_type, attributes,
          ).collect()
          for i in 0..<members.length() {
            pending.push(members[members.length() - 1 - i])
          }
        }
        SingleType(PromiseType(promise_type)) =>
          pending.push((promise_type.type_, []))
        SingleType(DistinguishableType(distinguishable_type)) =>
          match distinguishable_type {
            Sequence(inner, _)
            | AsyncSequence(inner, _)
            | FrozenArray(inner, _)
            | ObservableArray(inner, _) =>
              pending.push(
                (inner.type_, inner.extended_attribute_list.iter().collect()),
              )
            RecordType(record, _) => {
              let inner = record.type_with_extended_attributes
              pending.push(
                (inner.type_, inner.extended_attribute_list.iter().collect()),
              )
              if type_.iter_types().nth(1) is Some(key_type) {
                pending.push((key_type, []))
              }
            }
            _ => ()
          }
        SingleType(Any) => ()
      }
    }
    Some((type_, attributes))
  })
}

///|
/// For any type, the extended attributes associated with it must only contain
/// extended attributes that are applicable to types.
fn check_annotated_type(
  type_ : @parser.Type,
  attributes : Array[@parser.ExtendedAttribute],
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  for
    (_, attributes) in iter_types_with_extended_attributes(
      type_, attributes, typedefs,
    ) {
    assert_true(attributes.all(is_extended_attribute_applicable_to_types))
  }
}

///|
/// If type is the type of an argument A that is not declared with the
/// optional keyword, append to extended attributes all of the extended
/// attributes present in the ExtendedAttributeList of A's Argument production
/// that are applicable to types.
fn argument_type_extended_attributes(
  argument : @parser.Argument,
) -> Array[@parser.ExtendedAttribute] {
  match argument.argument_rest {
    Optional(type_with_extended_attributes, _, _) =>
      type_with_extended_attributes.extended_attribute_list.iter().collect()
    Ellipsisable(_, _, _) =>
      argument.extended_attribute_list
      .iter()
      .filter(is_extended_attribute_applicable_to_types)
      .collect()
  }
}

///|
/// If type is the type of a dictionary member M that is not required,
/// append to extended attributes all of the extended attributes present in
/// the ExtendedAttributeList of M's DictionaryMember production that are
/// applicable to types.
fn dictionary_member_type_extended_attributes(
  member_ : @parser.DictionaryMemberRest,
  member_attributes : @parser.ExtendedAttributeList,
) -> Array[@parser.ExtendedAttribute] {
  match member_ {
    Required(type_with_extended_attributes, _) =>
      type_with_extended_attributes.extended_attribute_list.iter().collect()
    Optional(_, _, _) =>
      member_attributes
      .iter()
      .filter(is_extended_attribute_applicable_to_types)
      .collect()
  }
}
