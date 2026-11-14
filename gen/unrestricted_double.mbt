///|
/// The unrestricted double type is a floating point numeric type that corresponds to the set of all possible double-precision 64-bit IEEE 754 floating point numbers, finite, non-finite, and special "not a number" values (NaNs).
/// unrestricted double constant values in IDL are represented with decimal tokens.
fn check_unrestricted_double_constant_value(
  value : @parser.ConstValue,
) -> Unit raise {
  assert_true(value is FloatLiteral(_))
}
