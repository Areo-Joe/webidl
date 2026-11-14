///|
/// The identifier of a constant must not be the same as the identifier of another
/// interface member or callback interface member defined on the same interface or callback interface.
fn check_constant_names_no_conflict(
  constant_names : Array[StringView],
  other_member_names : Array[StringView],
) -> Unit raise {
  let names = Set(constant_names)
  assert_eq(names.length(), constant_names.length())
  assert_false(other_member_names.any(name => names.contains(name)))
}

///|
fn check_constant_names_on_interface(interface : Interface) -> Unit raise {
  let constant_names = []
  let other_member_names = []
  let members = interface.members.filter_map(member_ => {
    if member_.body is PartialInterfaceMember(body) {
      Some(body)
    } else {
      None
    }
  })
  for partial in interface.partials {
    members.push_iter(partial.members.iter().map(member_ => member_.body))
  }
  for member_ in members {
    if member_ is Const(constant) {
      constant_names.push(strip_underscore(constant.identifier))
    } else if Attribute::from_partial_interface_member(member_)
      is Some(attribute) {
      other_member_names.push(name_of_attribute(attribute))
    } else if Operation::from_partial_interface_member(member_)
      is Some(operation) {
      if name_of_operation(operation) is Some(name) {
        other_member_names.push(name)
      }
    }
  }
  let mixin_members = []
  for mixin_ in interface.mixins {
    mixin_members.push_iter(mixin_.members.iter().map(member_ => member_.body))
    for partial in mixin_.partials {
      mixin_members.push_iter(
        partial.members.iter().map(member_ => member_.body),
      )
    }
  }
  for member_ in mixin_members {
    if member_ is Const(constant) {
      constant_names.push(strip_underscore(constant.identifier))
    } else if Attribute::from_mixin_member(member_) is Some(attribute) {
      other_member_names.push(name_of_attribute(attribute))
    } else if Operation::from_interface_mixin_member(member_) is Some(operation) {
      if name_of_operation(operation) is Some(name) {
        other_member_names.push(name)
      }
    }
  }
  check_constant_names_no_conflict(constant_names, other_member_names)
}

///|
fn check_constant_names_on_callback_interface(
  callback_interface : CallbackInterface,
) -> Unit raise {
  let constant_names = []
  let other_member_names = []
  for (_, member_) in callback_interface.members.iter() {
    if member_ is Const(constant) {
      constant_names.push(strip_underscore(constant.identifier))
    } else if Operation::from_callback_interface_member(member_)
      is Some(operation) {
      if name_of_operation(operation) is Some(name) {
        other_member_names.push(name)
      }
    }
  }
  check_constant_names_no_conflict(constant_names, other_member_names)
}

///|
/// If an identifier is used, it must reference a typedef whose type is a primitive type.
fn primitive_type_of_constant(
  type_ : @parser.ConstType,
  typedefs : Array[TypeDef],
) -> @parser.PrimitiveType raise {
  match type_ {
    PrimitiveType(primitive_type) => primitive_type
    Identifier(identifier) => {
      for typedef_ in typedefs {
        if strip_underscore(typedef_.identifier) == strip_underscore(identifier) &&
          typedef_.type_with_extended_attributes.type_
          is SingleType(
            DistinguishableType(PrimitiveType(primitive_type, None))
          ) {
          return primitive_type
        }
      }
      fail("Expected a typedef whose type is a primitive type")
    }
  }
}

///|
fn check_constant_value(
  type_ : @parser.PrimitiveType,
  value : @parser.ConstValue,
) -> Unit raise {
  match type_ {
    Boolean => check_boolean_constant_value(value)
    Byte => check_byte_constant_value(value)
    Octet => check_octet_constant_value(value)
    UnsignedIntegerType(IntegerType(Short)) => check_short_constant_value(value)
    UnsignedIntegerType(UnsignedIntegerType(Short)) =>
      check_unsigned_short_constant_value(value)
    UnsignedIntegerType(IntegerType(Long(None))) =>
      check_long_constant_value(value)
    UnsignedIntegerType(UnsignedIntegerType(Long(None))) =>
      check_unsigned_long_constant_value(value)
    UnsignedIntegerType(IntegerType(Long(Long))) =>
      check_long_long_constant_value(value)
    UnsignedIntegerType(UnsignedIntegerType(Long(Long))) =>
      check_unsigned_long_long_constant_value(value)
    UnrestrictedFloatType(FloatType(Float)) => check_float_constant_value(value)
    UnrestrictedFloatType(UnrestrictedFloatType(Float)) =>
      check_unrestricted_float_constant_value(value)
    UnrestrictedFloatType(FloatType(Double)) =>
      check_double_constant_value(value)
    UnrestrictedFloatType(UnrestrictedFloatType(Double)) =>
      check_unrestricted_double_constant_value(value)
    Bigint => check_bigint_constant_value(value)
  }
}
