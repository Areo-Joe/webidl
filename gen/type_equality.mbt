///|
fn same_flattened_member_type(
  left : @parser.Type,
  right : @parser.Type,
  typedefs : Map[StringView, TypeDef],
) -> Bool {
  same_type(left, right, typedefs, ignore_outer=true)
}

///|
fn same_type(
  left : @parser.Type,
  right : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  left_attributes~ : Array[@parser.ExtendedAttribute] = [],
  right_attributes~ : Array[@parser.ExtendedAttribute] = [],
  ignore_outer~ : Bool = false,
) -> Bool {
  let visiting : Array[
    (
      @parser.Type,
      @parser.Type,
      Array[@parser.ExtendedAttribute],
      Array[@parser.ExtendedAttribute],
    ),
  ] = []

  fn flatten_union(
    union_type : @parser.UnionType,
    attributes : Array[@parser.ExtendedAttribute],
  ) -> (Array[(@parser.Type, Array[@parser.ExtendedAttribute])], Bool) {
    let pending : Array[(@parser.Type, Array[@parser.ExtendedAttribute])] = []
    let visited : Array[(@parser.Type, Array[@parser.ExtendedAttribute])] = []
    let types : Array[(@parser.Type, Array[@parser.ExtendedAttribute])] = []

    pending.push_iter(
      union_member_types_with_extended_attributes(union_type, attributes),
    )
    let mut nullable = false
    while pending.pop() is Some((type_, attributes)) {
      let (type_, type_nullable, attributes) = resolve_type_with_extended_attributes(
        type_, attributes, typedefs,
      )
      nullable = nullable || type_nullable
      match type_ {
        UnionType(union_type, _) =>
          if !visited.any(previous => {
              physical_equal(previous.0, type_) &&
              same_type_attributes(previous.1, attributes)
            }) {
            visited.push((type_, attributes))
            pending.push_iter(
              union_member_types_with_extended_attributes(
                union_type, attributes,
              ),
            )
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

    let (left, left_nullable, left_attributes) = resolve_type_with_extended_attributes(
      left, left_attributes, typedefs,
    )
    let (right, right_nullable, right_attributes) = resolve_type_with_extended_attributes(
      right, right_attributes, typedefs,
    )
    if !ignore_outer &&
      (
        left_nullable != right_nullable ||
        !same_type_attributes(left_attributes, right_attributes)
      ) {
      return false
    }
    if visiting.any(state => {
        physical_equal(state.0, left) &&
        physical_equal(state.1, right) &&
        same_type_attributes(state.2, left_attributes) &&
        same_type_attributes(state.3, right_attributes)
      }) {
      return true
    }
    visiting.push((left, right, left_attributes, right_attributes))
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
        let (left, left_nullable) = flatten_union(left, left_attributes)
        let (right, right_nullable) = flatten_union(right, right_attributes)
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

  same(left, right, ignore_outer, left_attributes, right_attributes)
}
