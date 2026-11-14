///|
priv enum LegacyWindowAlias {
  Ident(StringView)
  IdentList(Array[StringView])
}

///|
fn is_valid_legacy_window_alias(
  attr : @parser.ExtendedAttribute,
) -> LegacyWindowAlias? {
  match attr {
    Ident({ identifier: "LegacyWindowAlias", value, }) => Some(Ident(value))
    IdentList({ identifier: "LegacyWindowAlias", identifier_list, }) =>
      Some(IdentList(identifier_list.iter().collect()))
    _ => None
  }
}

///|
fn legacy_window_alias_names(
  attr_list : @parser.ExtendedAttributeList,
) -> Array[StringView] {
  attr_list
  .iter()
  .filter_map(is_valid_legacy_window_alias)
  .map(window_alias => {
    match window_alias {
      Ident(value) => [strip_underscore(value)]
      IdentList(values) => values.map(strip_underscore)
    }
  })
  .collect()
  .flatten()
}
