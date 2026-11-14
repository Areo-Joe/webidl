///|
fn check_callback_interfaces(
  callback_interfaces : Array[CallbackInterface],
) -> Unit raise {
  for callback_interface in callback_interfaces {
    check_callback_interface_has_one_regular_operation(callback_interface)
    check_constant_names_on_callback_interface(callback_interface)
    if callback_interface.members.iter().any(member_ => member_.1 is Const(_)) {
      check_exposed_on_callback_interface(callback_interface)
    }
  }
}

///|
/// Callback interfaces must define exactly one regular operation.
fn check_callback_interface_has_one_regular_operation(
  callback_interface : CallbackInterface,
) -> Unit raise {
  assert_eq(
    callback_interface.members
    .iter()
    .filter(member_ => member_.1 is RegularOperation(_))
    .count(),
    1,
  )
}
