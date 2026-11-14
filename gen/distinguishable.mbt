///|
priv enum TypeCategory {
  Undefined
  Boolean
  Numeric
  Bigint
  String
  Object
  Symbol
  InterfaceLike
  CallbackFunction
  DictionaryLike
  AsyncSequence
  SequenceLike
}

///|
/// Two types are distinguishable if the following algorithm returns true.
fn are_types_distinguishable(
  left : @parser.Type,
  right : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Bool {
  fn flatten(type_ : @parser.Type) -> (Array[@parser.Type], Bool, Bool) {
    let pending = [type_]
    let visited : Set[StringView] = Set([])
    let members = []
    let mut includes_nullable = false
    let mut has_dictionary = false
    while pending.pop() is Some(type_) {
      includes_nullable = includes_nullable || is_nullable_type(type_)
      match type_ {
        UnionType(union_type, _) =>
          pending.push_iter(union_type.iter_member_types())
        SingleType(DistinguishableType(Identifier(identifier, _))) => {
          let name = strip_underscore(identifier)
          if typedefs.get(name) is Some(typedef_) {
            if !visited.contains(name) {
              visited.add(name)
              pending.push(typedef_.type_with_extended_attributes.type_)
            }
          } else {
            if definitions.get(name) is Some(Dictionary(_)) {
              has_dictionary = true
            }
            members.push(type_)
          }
        }
        _ => members.push(type_)
      }
    }
    (members, includes_nullable, has_dictionary)
  }

  let (left_members, left_nullable, left_dictionary) = flatten(left)
  let (right_members, right_nullable, right_dictionary) = flatten(right)
  if (left_nullable && (right_nullable || right_dictionary)) ||
    (right_nullable && left_dictionary) {
    return false
  }
  left_members.all(left => {
    right_members.all(right => {
      are_flattened_member_types_distinguishable(left, right, definitions)
    })
  })
}

///|
fn type_category(
  type_ : @parser.Type,
  definitions : Map[StringView, Definition],
) -> TypeCategory? {
  match type_ {
    SingleType(DistinguishableType(type_)) =>
      match type_ {
        Undefined(_) => Some(Undefined)
        PrimitiveType(Boolean, _) => Some(Boolean)
        PrimitiveType(Bigint, _) => Some(Bigint)
        PrimitiveType(_, _) => Some(Numeric)
        StringType(_, _) => Some(String)
        Object(_) => Some(Object)
        Symbol(_) => Some(Symbol)
        BufferRelatedType(_, _) => Some(InterfaceLike)
        RecordType(_, _) => Some(DictionaryLike)
        AsyncSequence(_, _) => Some(AsyncSequence)
        Sequence(_, _) | FrozenArray(_, _) => Some(SequenceLike)
        Identifier(name, _) =>
          match definitions.get(strip_underscore(name)) {
            Some(Interface(_)) => Some(InterfaceLike)
            Some(Callback(_)) => Some(CallbackFunction)
            Some(Dictionary(_) | CallbackInterface(_)) => Some(DictionaryLike)
            Some(Enum(_)) => Some(String)
            _ => None
          }
        ObservableArray(_, _) => None
      }
    SingleType(Any | PromiseType(_)) | UnionType(_, _) => None
  }
}

///|
fn interface_inherits(interface : Interface, name : StringView) -> Bool {
  let mut current = interface.inheritance
  while current is Some(interface) {
    if name_of_interface(interface) == name {
      return true
    }
    current = interface.inheritance
  }
  false
}

///|
/// The two identified interface-like types are not the same,
/// and no single platform object implements both interface-like types.
fn are_interface_like_types_distinguishable(
  left : @parser.Type,
  right : @parser.Type,
  definitions : Map[StringView, Definition],
) -> Bool {
  match (left, right) {
    (
      SingleType(DistinguishableType(Identifier(left, _))),
      SingleType(DistinguishableType(Identifier(right, _))),
    ) => {
      let left = strip_underscore(left)
      let right = strip_underscore(right)
      guard definitions.get(left) is Some(Interface(left_interface)) &&
        definitions.get(right) is Some(Interface(right_interface)) else {
        false
      }
      left != right &&
      !interface_inherits(left_interface, right) &&
      !interface_inherits(right_interface, left)
    }
    (
      SingleType(DistinguishableType(BufferRelatedType(left, _))),
      SingleType(DistinguishableType(BufferRelatedType(right, _))),
    ) => name_of_buffer_type(left) != name_of_buffer_type(right)
    _ => true
  }
}

///|
/// Consider the two "innermost" types derived by taking each type's inner type
/// if it is an annotated type, and then taking its inner type inner type if
/// the result is a nullable type.
fn are_flattened_member_types_distinguishable(
  left : @parser.Type,
  right : @parser.Type,
  definitions : Map[StringView, Definition],
) -> Bool {
  guard type_category(left, definitions) is Some(left_category) &&
    type_category(right, definitions) is Some(right_category) else {
    false
  }
  match (left_category, right_category) {
    (InterfaceLike, InterfaceLike) =>
      are_interface_like_types_distinguishable(left, right, definitions)
    (CallbackFunction, DictionaryLike) =>
      callback_distinguishable_from_dictionary_like(left, definitions)
    (DictionaryLike, CallbackFunction) =>
      callback_distinguishable_from_dictionary_like(right, definitions)
    (Undefined, Undefined)
    | (Boolean, Boolean)
    | (Numeric, Numeric)
    | (Bigint, Bigint)
    | (String, String)
    | (Object, Object)
    | (Symbol, Symbol)
    | (CallbackFunction, CallbackFunction)
    | (DictionaryLike, DictionaryLike)
    | (AsyncSequence, AsyncSequence)
    | (AsyncSequence, SequenceLike)
    | (SequenceLike, AsyncSequence)
    | (SequenceLike, SequenceLike)
    | (Undefined, DictionaryLike)
    | (DictionaryLike, Undefined)
    | (
      Object,
      InterfaceLike
      | CallbackFunction
      | DictionaryLike
      | AsyncSequence
      | SequenceLike,
    )
    | (
      InterfaceLike
      | CallbackFunction
      | DictionaryLike
      | AsyncSequence
      | SequenceLike,
      Object,
    ) => false
    _ => true
  }
}

///|
/// A callback function that does not have [LegacyTreatNonObjectAsNull]
/// extended attribute is distinguishable from a type in the dictionary-like category.
fn callback_distinguishable_from_dictionary_like(
  type_ : @parser.Type,
  definitions : Map[StringView, Definition],
) -> Bool {
  guard type_ is SingleType(DistinguishableType(Identifier(name, _))) &&
    definitions.get(strip_underscore(name)) is Some(Callback(callback)) else {
    false
  }
  !callback.extended_attribute_list
  .iter()
  .any(is_valid_legacy_treat_non_object_as_null)
}
