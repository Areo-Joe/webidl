///|
/// The long type corresponds to 32-bit signed integers.
/// long constant values in IDL are represented with integer tokens.
fn check_long_constant_value(value : @parser.ConstValue) -> Unit raise {
  ignore(integer_constant_value(value))
}
