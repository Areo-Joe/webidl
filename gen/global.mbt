///|
fn global_names(attr_list : @parser.ExtendedAttributeList) -> Array[StringView] {
  attr_list
  .iter()
  .filter_map(x => {
    match x {
      Ident({ identifier: "Global", value }) => Some([strip_underscore(value)])
      IdentList({ identifier: "Global", identifier_list }) =>
        Some(identifier_list.iter().map(strip_underscore).collect())
      _ => None
    }
  })
  .collect()
  .flatten()
}
