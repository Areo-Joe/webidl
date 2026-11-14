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
