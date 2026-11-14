///|
/// The inner type must not be:
/// * an observable array type,
fn check_nullable_type_no_observable_array(type_ : @parser.Type) -> Unit raise {
  assert_false(
    type_
    .iter_types()
    .any(type_ => {
      type_ is SingleType(DistinguishableType(ObservableArray(_, Some)))
    }),
  )
}
