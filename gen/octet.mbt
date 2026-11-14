///|
/// The octet type corresponds to 8-bit unsigned integers.
/// octet constant values in IDL are represented with integer tokens.
fn check_octet_constant_value(value : @parser.ConstValue) -> Unit raise {
  let number = integer_constant_value(value)
  assert_true(number >= 0 && number <= 255)
}
