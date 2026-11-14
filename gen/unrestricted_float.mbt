///|
/// The unrestricted float type is a floating point numeric type that corresponds to the set of all possible single-precision 32-bit IEEE 754 floating point numbers, finite, non-finite, and special "not a number" values (NaNs).
/// unrestricted float constant values in IDL are represented with decimal tokens.
fn check_unrestricted_float_constant_value(
  value : @parser.ConstValue,
) -> Unit raise {
  assert_true(value is FloatLiteral(_))
}
