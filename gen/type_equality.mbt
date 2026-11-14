///|
fn same_type_attributes(
  left : Array[@parser.ExtendedAttribute],
  right : Array[@parser.ExtendedAttribute],
) -> Bool {
  fn same_attribute(
    left : @parser.ExtendedAttribute,
    right : @parser.ExtendedAttribute,
  ) -> Bool {
    match (left, right) {
      (NoArgs(left), NoArgs(right)) => left.identifier == right.identifier
      _ => physical_equal(left, right)
    }
  }
  left
  .iter()
  .all(left => right.iter().any(right => same_attribute(left, right))) &&
  right
  .iter()
  .all(right => left.iter().any(left => same_attribute(left, right)))
}

///|
fn same_flattened_member_type(
  left : @parser.Type,
  right : @parser.Type,
  typedefs : Map[StringView, TypeDef],
) -> Bool {
  let visiting : Array[(@parser.Type, @parser.Type)] = []

  fn resolve(
    type_ : @parser.Type,
    attributes : Array[@parser.ExtendedAttribute],
  ) -> (@parser.Type, Bool, Array[@parser.ExtendedAttribute]) {
    let mut current = type_
    let mut nullable = false
    let attributes = attributes.copy()
    let visited : Set[StringView] = Set([])
    while current is SingleType(DistinguishableType(Identifier(name, _))) {
      nullable = nullable || is_nullable_type(current)
      let name = strip_underscore(name)
      guard typedefs.get(name) is Some(target) && !visited.contains(name) else {
        break
      }
      visited.add(name)
      attributes.push_iter(
        target.type_with_extended_attributes.extended_attribute_list.iter(),
      )
      current = target.type_with_extended_attributes.type_
    }
    (current, nullable || is_nullable_type(current), attributes)
  }

  fn flatten_union(
    union_type : @parser.UnionType,
  ) -> (Array[(@parser.Type, Array[@parser.ExtendedAttribute])], Bool) {
    let pending : Array[(@parser.Type, Array[@parser.ExtendedAttribute])] = []
    let visited : Array[(@parser.Type, Array[@parser.ExtendedAttribute])] = []
    let types : Array[(@parser.Type, Array[@parser.ExtendedAttribute])] = []

    fn push_members(
      union_type : @parser.UnionType,
      inherited_attributes : Array[@parser.ExtendedAttribute],
    ) -> Unit {
      for
        (type_, union_member) in union_type
        .iter_member_types()
        .zip(union_type.iter()) {
        let attributes = inherited_attributes.copy()
        if union_member
          is DistinguishableTypeWithExtendedAttributeList(
            _,
            extended_attributes
          ) {
          attributes.push_iter(extended_attributes.iter())
        }
        pending.push((type_, attributes))
      }
    }

    push_members(union_type, [])
    let mut nullable = false
    while pending.pop() is Some((type_, attributes)) {
      let (type_, type_nullable, attributes) = resolve(type_, attributes)
      nullable = nullable || type_nullable
      match type_ {
        UnionType(union_type, _) =>
          if !visited.any(previous => {
              physical_equal(previous.0, type_) &&
              same_type_attributes(previous.1, attributes)
            }) {
            visited.push((type_, attributes))
            push_members(union_type, attributes)
          }
        _ => types.push((type_, attributes))
      }
    }
    (types, nullable)
  }

  fn same(
    left : @parser.Type,
    right : @parser.Type,
    ignore_outer : Bool,
    left_attributes : Array[@parser.ExtendedAttribute],
    right_attributes : Array[@parser.ExtendedAttribute],
  ) -> Bool {
    fn same_annotated(
      left : @parser.TypeWithExtendedAttributes,
      right : @parser.TypeWithExtendedAttributes,
    ) -> Bool {
      same(
        left.type_,
        right.type_,
        false,
        left.extended_attribute_list.iter().collect(),
        right.extended_attribute_list.iter().collect(),
      )
    }

    let (left, left_nullable, left_attributes) = resolve(left, left_attributes)
    let (right, right_nullable, right_attributes) = resolve(
      right, right_attributes,
    )
    if !ignore_outer &&
      (
        left_nullable != right_nullable ||
        !same_type_attributes(left_attributes, right_attributes)
      ) {
      return false
    }
    if visiting.any(state => {
        physical_equal(state.0, left) && physical_equal(state.1, right)
      }) {
      return true
    }
    visiting.push((left, right))
    let result = match (left, right) {
      (SingleType(Any), SingleType(Any)) => true
      (SingleType(PromiseType(left)), SingleType(PromiseType(right))) =>
        same(left.type_, right.type_, false, [], [])
      (UnionType(left, _), UnionType(right, _)) => {
        fn same_member(
          left : (@parser.Type, Array[@parser.ExtendedAttribute]),
          right : (@parser.Type, Array[@parser.ExtendedAttribute]),
        ) -> Bool {
          same_type_attributes(left.1, right.1) &&
          same(left.0, right.0, true, [], [])
        }
        let (left, left_nullable) = flatten_union(left)
        let (right, right_nullable) = flatten_union(right)
        left_nullable == right_nullable &&
        left.all(left => right.any(right => same_member(left, right))) &&
        right.all(right => left.any(left => same_member(left, right)))
      }
      (
        SingleType(DistinguishableType(left)),
        SingleType(DistinguishableType(right)),
      ) =>
        match (left, right) {
          (PrimitiveType(left, _), PrimitiveType(right, _)) =>
            name_of_primitive_type(left) == name_of_primitive_type(right)
          (StringType(left, _), StringType(right, _)) =>
            name_of_string_type(left) == name_of_string_type(right)
          (BufferRelatedType(left, _), BufferRelatedType(right, _)) =>
            name_of_buffer_type(left) == name_of_buffer_type(right)
          (Identifier(left, _), Identifier(right, _)) =>
            strip_underscore(left) == strip_underscore(right)
          (Object(_), Object(_))
          | (Symbol(_), Symbol(_))
          | (Undefined(_), Undefined(_)) => true
          (Sequence(left, _), Sequence(right, _))
          | (AsyncSequence(left, _), AsyncSequence(right, _))
          | (FrozenArray(left, _), FrozenArray(right, _))
          | (ObservableArray(left, _), ObservableArray(right, _)) =>
            same_annotated(left, right)
          (RecordType(left, _), RecordType(right, _)) =>
            name_of_string_type(left.string_type) ==
            name_of_string_type(right.string_type) &&
            same_annotated(
              left.type_with_extended_attributes,
              right.type_with_extended_attributes,
            )
          _ => false
        }
      _ => false
    }
    ignore(visiting.pop())
    result
  }

  same(left, right, true, [], [])
}
