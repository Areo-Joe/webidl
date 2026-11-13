///|
pub type Tokens = ArrayView[(@lexer.TokenType, StringView)]

///|
pub struct Constructor {
  argument_list : ArgumentList
}

///|
pub fn Constructor::parse(input : Tokens) -> (Constructor, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "constructor"),
      (@lexer.TokenType::Punctuation, "("),
      .. after_constructor_start,
    ] &&
    ArgumentList::parse(after_constructor_start)
    is (
      argument_list,
      [
        (@lexer.TokenType::Punctuation, ")"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((Constructor::{ argument_list, }, rest))
  }

  return None
}

///|
pub struct Const {
  const_type : ConstType
  identifier : StringView
  const_value : ConstValue
}

///|
pub fn Const::parse(input : Tokens) -> (Const, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "const"), .. after_const] &&
    ConstType::parse(after_const)
    is Some(
      (
        const_type,
        [
          (@lexer.TokenType::Identifier, identifier),
          (@lexer.TokenType::Punctuation, "="),
          .. after_equal,
        ],
      )
    ) &&
    ConstValue::parse(after_equal)
    is Some((const_value, [(@lexer.TokenType::Punctuation, ";"), .. rest])) {
    return Some((Const::{ const_type, identifier, const_value, }, rest))
  }

  return None
}

///|
pub enum OptionalReadOnly {
  ReadOnly
  None
} derive(Debug)

///|
pub extend OptionalReadOnly with @debug.Debug::{to_repr}

///|
pub fn OptionalReadOnly::parse(input : Tokens) -> (OptionalReadOnly, Tokens) {
  if input is [(@lexer.TokenType::Keyword, "readonly"), .. rest] {
    return (OptionalReadOnly::ReadOnly, rest)
  }
  return (OptionalReadOnly::None, input)
}

///|
pub enum StaticMemberRest {
  Attribute(OptionalReadOnly, AttributeRest)
  RegularOperation(RegularOperation)
}

///|
pub fn StaticMemberRest::parse(input : Tokens) -> (StaticMemberRest, Tokens)? {
  if OptionalReadOnly::parse(input)
    is (optional_read_only, after_optional_read_only) &&
    AttributeRest::parse(after_optional_read_only)
    is Some((attribute_rest, rest)) {
    return Some(
      (StaticMemberRest::Attribute(optional_read_only, attribute_rest), rest),
    )
  }

  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some((StaticMemberRest::RegularOperation(regular_operation), rest))
  }

  None
}

///|
pub struct StaticMember {
  static_member_rest : StaticMemberRest
}

///|
pub fn StaticMember::parse(input : Tokens) -> (StaticMember, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "static"), .. after_static] &&
    StaticMemberRest::parse(after_static) is Some((static_member_rest, rest)) {
    return Some((StaticMember::{ static_member_rest, }, rest))
  }

  None
}

///|
pub enum OptionalType {
  Some(TypeWithExtendedAttributes)
  None
}

///|
pub fn OptionalType::parse(input : Tokens) -> (OptionalType, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, ","), .. after_comma] &&
    TypeWithExtendedAttributes::parse(after_comma)
    is Some((type_with_extended_attributes, rest)) {
    return (OptionalType::Some(type_with_extended_attributes), rest)
  }
  return (OptionalType::None, input)
}

///|
pub struct Iterable {
  type_with_extended_attributes : TypeWithExtendedAttributes
  optional_type : OptionalType
}

///|
pub fn Iterable::parse(input : Tokens) -> (Iterable, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "iterable"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_iterable_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_iterable_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    OptionalType::parse(after_type_with_extended_attributes)
    is (
      optional_type,
      [
        (@lexer.TokenType::Punctuation, ">"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (Iterable::{ type_with_extended_attributes, optional_type, }, rest),
    )
  }

  None
}

///|
pub enum OptionalArgumentList {
  Some(ArgumentList)
  None
}

///|
pub fn OptionalArgumentList::parse(
  input : Tokens,
) -> (OptionalArgumentList, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, "("), .. after_open_paren] &&
    ArgumentList::parse(after_open_paren)
    is (argument_list, [(@lexer.TokenType::Punctuation, ")"), .. rest]) {
    return (OptionalArgumentList::Some(argument_list), rest)
  }

  return (OptionalArgumentList::None, input)
}

///|
pub struct AsyncIterable {
  type_with_extended_attributes : TypeWithExtendedAttributes
  optional_type : OptionalType
  optional_argument_list : OptionalArgumentList
}

///|
pub fn AsyncIterable::parse(input : Tokens) -> (AsyncIterable, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "async_iterable"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_async_iterable_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_async_iterable_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    OptionalType::parse(after_type_with_extended_attributes)
    is (
      optional_type,
      [(@lexer.TokenType::Punctuation, ">"), .. after_async_iterable_end],
    ) &&
    OptionalArgumentList::parse(after_async_iterable_end)
    is (optional_argument_list, [(@lexer.TokenType::Punctuation, ";"), .. rest]) {
    return Some(
      (
        AsyncIterable::{
          type_with_extended_attributes,
          optional_type,
          optional_argument_list,
        },
        rest,
      ),
    )
  }

  None
}

///|
pub struct MaplikeRest {
  key_type : TypeWithExtendedAttributes
  value_type : TypeWithExtendedAttributes
}

///|
pub fn MaplikeRest::parse(input : Tokens) -> (MaplikeRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "maplike"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_maplike_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_maplike_start)
    is Some((key_type, [(@lexer.TokenType::Punctuation, ","), .. after_comma])) &&
    TypeWithExtendedAttributes::parse(after_comma)
    is Some(
      (
        value_type,
        [
          (@lexer.TokenType::Punctuation, ">"),
          (@lexer.TokenType::Punctuation, ";"),
          .. rest,
        ],
      )
    ) {
    return Some((MaplikeRest::{ key_type, value_type, }, rest))
  }

  None
}

///|
pub struct SetlikeRest {
  type_with_extended_attributes : TypeWithExtendedAttributes
}

///|
pub fn SetlikeRest::parse(input : Tokens) -> (SetlikeRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "setlike"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_setlike_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_setlike_start)
    is Some(
      (
        type_with_extended_attributes,
        [
          (@lexer.TokenType::Punctuation, ">"),
          (@lexer.TokenType::Punctuation, ";"),
          .. rest,
        ],
      )
    ) {
    return Some((SetlikeRest::{ type_with_extended_attributes, }, rest))
  }

  None
}

///|
pub enum ReadOnlyMemberRest {
  Attribute(AttributeRest)
  Maplike(MaplikeRest)
  Setlike(SetlikeRest)
}

///|
pub fn ReadOnlyMemberRest::parse(
  input : Tokens,
) -> (ReadOnlyMemberRest, Tokens)? {
  if AttributeRest::parse(input) is Some((attribute_rest, rest)) {
    return Some((ReadOnlyMemberRest::Attribute(attribute_rest), rest))
  }

  if MaplikeRest::parse(input) is Some((maplike_rest, rest)) {
    return Some((ReadOnlyMemberRest::Maplike(maplike_rest), rest))
  }

  if SetlikeRest::parse(input) is Some((setlike_rest, rest)) {
    return Some((ReadOnlyMemberRest::Setlike(setlike_rest), rest))
  }

  None
}

///|
pub struct ReadOnlyMember {
  read_only_member_rest : ReadOnlyMemberRest
}

///|
pub fn ReadOnlyMember::parse(input : Tokens) -> (ReadOnlyMember, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "readonly"), .. after_readonly] &&
    ReadOnlyMemberRest::parse(after_readonly)
    is Some((read_only_member_rest, rest)) {
    return Some((ReadOnlyMember::{ read_only_member_rest, }, rest))
  }

  None
}

///|
pub struct ReadWriteMaplike {
  maplike_rest : MaplikeRest
}

///|
pub fn ReadWriteMaplike::parse(input : Tokens) -> (ReadWriteMaplike, Tokens)? {
  if MaplikeRest::parse(input) is Some((maplike_rest, rest)) {
    return Some((ReadWriteMaplike::{ maplike_rest, }, rest))
  }

  None
}

///|
pub struct ReadWriteSetlike {
  setlike_rest : SetlikeRest
}

///|
pub fn ReadWriteSetlike::parse(input : Tokens) -> (ReadWriteSetlike, Tokens)? {
  if SetlikeRest::parse(input) is Some((setlike_rest, rest)) {
    return Some((ReadWriteSetlike::{ setlike_rest, }, rest))
  }

  None
}

///|
pub enum PartialInterfaceMember {
  Const(Const)
  Operation(Operation)
  Stringifier(Stringifier)
  StaticMember(StaticMember)
  Iterable(Iterable)
  AsyncIterable(AsyncIterable)
  ReadOnlyMember(ReadOnlyMember)
  ReadWriteAttribute(ReadWriteAttribute)
  ReadWriteMaplike(ReadWriteMaplike)
  ReadWriteSetlike(ReadWriteSetlike)
  InheritAttribute(InheritAttribute)
}

///|
pub fn PartialInterfaceMember::parse(
  input : Tokens,
) -> (PartialInterfaceMember, Tokens)? {
  if Const::parse(input) is Some((const_, rest)) {
    return Some((PartialInterfaceMember::Const(const_), rest))
  }

  if Operation::parse(input) is Some((operation, rest)) {
    return Some((PartialInterfaceMember::Operation(operation), rest))
  }

  if Stringifier::parse(input) is Some((stringifier, rest)) {
    return Some((PartialInterfaceMember::Stringifier(stringifier), rest))
  }

  if StaticMember::parse(input) is Some((static_member, rest)) {
    return Some((PartialInterfaceMember::StaticMember(static_member), rest))
  }

  if Iterable::parse(input) is Some((iterable, rest)) {
    return Some((PartialInterfaceMember::Iterable(iterable), rest))
  }

  if AsyncIterable::parse(input) is Some((async_iterable, rest)) {
    return Some((PartialInterfaceMember::AsyncIterable(async_iterable), rest))
  }

  if ReadOnlyMember::parse(input) is Some((read_only_member, rest)) {
    return Some(
      (PartialInterfaceMember::ReadOnlyMember(read_only_member), rest),
    )
  }

  if ReadWriteAttribute::parse(input) is Some((read_write_attribute, rest)) {
    return Some(
      (PartialInterfaceMember::ReadWriteAttribute(read_write_attribute), rest),
    )
  }

  if ReadWriteMaplike::parse(input) is Some((read_write_maplike, rest)) {
    return Some(
      (PartialInterfaceMember::ReadWriteMaplike(read_write_maplike), rest),
    )
  }

  if ReadWriteSetlike::parse(input) is Some((read_write_setlike, rest)) {
    return Some(
      (PartialInterfaceMember::ReadWriteSetlike(read_write_setlike), rest),
    )
  }

  if InheritAttribute::parse(input) is Some((inherit_attribute, rest)) {
    return Some(
      (PartialInterfaceMember::InheritAttribute(inherit_attribute), rest),
    )
  }

  None
}

///|
pub enum PartialInterfaceMembers {
  Some(ExtendedAttributeList, PartialInterfaceMember, PartialInterfaceMembers)
  None
}

///|
pub fn PartialInterfaceMembers::iter(
  self : Self,
) -> Iter[(ExtendedAttributeList, PartialInterfaceMember)] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(attribute_list, current_member, rest) => {
        target = rest

        Some((attribute_list, current_member))
      }
      None => None
    }
  })
}

///|
pub fn PartialInterfaceMembers::parse(
  input : Tokens,
) -> (PartialInterfaceMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    PartialInterfaceMember::parse(after_extended_attribute_list)
    is Some((partial_interface_member, after_partial_interface_member)) &&
    PartialInterfaceMembers::parse(after_partial_interface_member)
    is (partial_interface_members, rest) {
    return (
      PartialInterfaceMembers::Some(
        extended_attribute_list, partial_interface_member, partial_interface_members,
      ),
      rest,
    )
  }

  (PartialInterfaceMembers::None, input)
}

///|
pub struct PartialInterfaceRest {
  identifier : StringView
  partial_interface_members : PartialInterfaceMembers
}

///|
pub fn PartialInterfaceRest::parse(
  input : Tokens,
) -> (PartialInterfaceRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_partial_interface_start,
    ] &&
    PartialInterfaceMembers::parse(after_partial_interface_start)
    is (
      partial_interface_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (PartialInterfaceRest::{ identifier, partial_interface_members, }, rest),
    )
  }

  None
}

///|
pub enum MixinMember {
  Const(Const)
  RegularOperation(RegularOperation)
  Stringifier(Stringifier)
  Attribute(OptionalReadOnly, AttributeRest)
}

///|
pub fn MixinMember::parse(input : Tokens) -> (MixinMember, Tokens)? {
  if Const::parse(input) is Some((const_, rest)) {
    return Some((MixinMember::Const(const_), rest))
  }

  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some((MixinMember::RegularOperation(regular_operation), rest))
  }

  if Stringifier::parse(input) is Some((stringifier, rest)) {
    return Some((MixinMember::Stringifier(stringifier), rest))
  }

  if OptionalReadOnly::parse(input)
    is (optional_read_only, after_optional_read_only) &&
    AttributeRest::parse(after_optional_read_only)
    is Some((attribute_rest, rest)) {
    return Some(
      (MixinMember::Attribute(optional_read_only, attribute_rest), rest),
    )
  }

  None
}

///|
pub enum MixinMembers {
  Some(ExtendedAttributeList, MixinMember, MixinMembers)
  None
}

///|
pub fn MixinMembers::iter(
  self : Self,
) -> Iter[(ExtendedAttributeList, MixinMember)] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(attribute_list, current_member, rest) => {
        target = rest

        Some((attribute_list, current_member))
      }
      None => None
    }
  })
}

///|
pub fn MixinMembers::parse(input : Tokens) -> (MixinMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    MixinMember::parse(after_extended_attribute_list)
    is Some((mixin_member, after_mixin_member)) &&
    MixinMembers::parse(after_mixin_member) is (mixin_members, rest) {
    return (
      MixinMembers::Some(extended_attribute_list, mixin_member, mixin_members),
      rest,
    )
  }

  (MixinMembers::None, input)
}

///|
pub struct MixinRest {
  identifier : StringView
  mixin_members : MixinMembers
}

///|
pub fn MixinRest::parse(input : Tokens) -> (MixinRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "mixin"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_mixin_start,
    ] &&
    MixinMembers::parse(after_mixin_start)
    is (
      mixin_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((MixinRest::{ identifier, mixin_members, }, rest))
  }

  None
}

///|
pub enum PartialInterfaceOrPartialMixin {
  PartialInterfaceRest(PartialInterfaceRest)
  MixinRest(MixinRest)
}

///|
pub fn PartialInterfaceOrPartialMixin::parse(
  input : Tokens,
) -> (PartialInterfaceOrPartialMixin, Tokens)? {
  if PartialInterfaceRest::parse(input) is Some((partial_interface_rest, rest)) {
    return Some(
      (
        PartialInterfaceOrPartialMixin::PartialInterfaceRest(
          partial_interface_rest,
        ),
        rest,
      ),
    )
  }

  if MixinRest::parse(input) is Some((mixin_rest, rest)) {
    return Some((PartialInterfaceOrPartialMixin::MixinRest(mixin_rest), rest))
  }

  None
}

///|
pub enum Inheritance {
  Some(StringView)
  None
}

///|
pub fn Inheritance::parse(input : Tokens) -> (Inheritance, Tokens) {
  if input
    is [
      (@lexer.TokenType::Punctuation, ":"),
      (@lexer.TokenType::Identifier, identifier),
      .. rest,
    ] {
    return (Inheritance::Some(identifier), rest)
  }

  (Inheritance::None, input)
}

///|
pub enum DictionaryMemberRest {
  Required(TypeWithExtendedAttributes, StringView)
  Optional(Type, StringView, Default)
}

///|
pub fn DictionaryMemberRest::parse(
  input : Tokens,
) -> (DictionaryMemberRest, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "required"), .. after_required] &&
    TypeWithExtendedAttributes::parse(after_required)
    is Some(
      (
        type_with_extended_attributes,
        [
          (@lexer.TokenType::Identifier, identifier),
          (@lexer.TokenType::Punctuation, ";"),
          .. rest,
        ],
      )
    ) {
    return Some(
      (
        DictionaryMemberRest::Required(
          type_with_extended_attributes, identifier,
        ),
        rest,
      ),
    )
  }

  if Type::parse(input)
    is Some(
      (type_, [(@lexer.TokenType::Identifier, identifier), .. after_identifier])
    ) &&
    Default::parse(after_identifier)
    is (default, [(@lexer.TokenType::Punctuation, ";"), .. rest]) {
    return Some(
      (DictionaryMemberRest::Optional(type_, identifier, default), rest),
    )
  }

  None
}

///|
pub struct DictionaryMember {
  extended_attribute_list : ExtendedAttributeList
  dictionary_member_rest : DictionaryMemberRest
}

///|
pub fn DictionaryMember::parse(input : Tokens) -> (DictionaryMember, Tokens)? {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    DictionaryMemberRest::parse(after_extended_attribute_list)
    is Some((dictionary_member_rest, rest)) {
    return Some(
      (
        DictionaryMember::{ extended_attribute_list, dictionary_member_rest, },
        rest,
      ),
    )
  }

  None
}

///|
pub enum DictionaryMembers {
  Some(DictionaryMember, DictionaryMembers)
  None
}

///|
pub fn DictionaryMembers::iter(self : Self) -> Iter[DictionaryMember] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(current_member, rest) => {
        target = rest

        Some(current_member)
      }
      None => None
    }
  })
}

///|
pub fn DictionaryMembers::parse(input : Tokens) -> (DictionaryMembers, Tokens) {
  if DictionaryMember::parse(input)
    is Some((dictionary_member, after_dictionary_member)) &&
    DictionaryMembers::parse(after_dictionary_member)
    is (dictionary_members, rest) {
    return (
      DictionaryMembers::Some(dictionary_member, dictionary_members),
      rest,
    )
  }

  (DictionaryMembers::None, input)
}

///|
pub struct Dictionary {
  identifier : StringView
  inheritance : Inheritance
  dictionary_members : DictionaryMembers
}

///|
pub fn Dictionary::parse(input : Tokens) -> (Dictionary, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "dictionary"),
      (@lexer.TokenType::Identifier, identifier),
      .. after_identifier,
    ] &&
    Inheritance::parse(after_identifier)
    is (
      inheritance,
      [(@lexer.TokenType::Punctuation, "{"), .. after_dictionary_start],
    ) &&
    DictionaryMembers::parse(after_dictionary_start)
    is (
      dictionary_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (Dictionary::{ identifier, inheritance, dictionary_members, }, rest),
    )
  }

  None
}

///|
pub struct PartialDictionary {
  identifier : StringView
  dictionary_members : DictionaryMembers
}

///|
pub fn PartialDictionary::parse(input : Tokens) -> (PartialDictionary, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "dictionary"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_dictionary_start,
    ] &&
    DictionaryMembers::parse(after_dictionary_start)
    is (
      dictionary_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((PartialDictionary::{ identifier, dictionary_members, }, rest))
  }

  None
}

///|
pub enum NamespaceMember {
  RegularOperation(RegularOperation)
  ReadOnlyAttribute(AttributeRest)
  Const(Const)
}

///|
pub fn NamespaceMember::parse(input : Tokens) -> (NamespaceMember, Tokens)? {
  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some((NamespaceMember::RegularOperation(regular_operation), rest))
  }

  if input is [(@lexer.TokenType::Keyword, "readonly"), .. after_readonly] &&
    AttributeRest::parse(after_readonly) is Some((attribute_rest, rest)) {
    return Some((NamespaceMember::ReadOnlyAttribute(attribute_rest), rest))
  }

  if Const::parse(input) is Some((const_, rest)) {
    return Some((NamespaceMember::Const(const_), rest))
  }

  None
}

///|
pub enum NamespaceMembers {
  Some(ExtendedAttributeList, NamespaceMember, NamespaceMembers)
  None
}

///|
pub fn NamespaceMembers::iter(
  self : Self,
) -> Iter[(ExtendedAttributeList, NamespaceMember)] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(attribute_list, current_member, rest) => {
        target = rest

        Some((attribute_list, current_member))
      }
      None => None
    }
  })
}

///|
pub fn NamespaceMembers::parse(input : Tokens) -> (NamespaceMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    NamespaceMember::parse(after_extended_attribute_list)
    is Some((namespace_member, after_namespace_member)) &&
    NamespaceMembers::parse(after_namespace_member) is (namespace_members, rest) {
    return (
      NamespaceMembers::Some(
        extended_attribute_list, namespace_member, namespace_members,
      ),
      rest,
    )
  }

  (NamespaceMembers::None, input)
}

///|
pub struct Namespace {
  identifier : StringView
  namespace_members : NamespaceMembers
}

///|
pub fn Namespace::parse(input : Tokens) -> (Namespace, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "namespace"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_namespace_start,
    ] &&
    NamespaceMembers::parse(after_namespace_start)
    is (
      namespace_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((Namespace::{ identifier, namespace_members, }, rest))
  }

  None
}

///|
pub enum PartialDefinition {
  Interface(PartialInterfaceOrPartialMixin)
  Dictionary(PartialDictionary)
  Namespace(Namespace)
}

///|
pub fn PartialDefinition::parse(input : Tokens) -> (PartialDefinition, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "interface"), .. after_interface] &&
    PartialInterfaceOrPartialMixin::parse(after_interface)
    is Some((partial_interface_or_partial_mixin, rest)) {
    return Some(
      (PartialDefinition::Interface(partial_interface_or_partial_mixin), rest),
    )
  }

  if PartialDictionary::parse(input) is Some((partial_dictionary, rest)) {
    return Some((PartialDefinition::Dictionary(partial_dictionary), rest))
  }

  if Namespace::parse(input) is Some((namespace_, rest)) {
    return Some((PartialDefinition::Namespace(namespace_), rest))
  }

  None
}

///|
pub struct Partial {
  partial_definition : PartialDefinition
}

///|
pub fn Partial::parse(input : Tokens) -> (Partial, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "partial"), .. after_partial] &&
    PartialDefinition::parse(after_partial) is Some((partial_definition, rest)) {
    return Some((Partial::{ partial_definition, }, rest))
  }

  None
}

///|
pub enum InterfaceMember {
  PartialInterfaceMember(PartialInterfaceMember)
  Constructor(Constructor)
}

///|
pub fn InterfaceMember::parse(input : Tokens) -> (InterfaceMember, Tokens)? {
  if PartialInterfaceMember::parse(input)
    is Some((partial_interface_member, rest)) {
    return Some(
      (InterfaceMember::PartialInterfaceMember(partial_interface_member), rest),
    )
  }

  if Constructor::parse(input) is Some((constructor_, rest)) {
    return Some((InterfaceMember::Constructor(constructor_), rest))
  }

  None
}

///|
pub enum InterfaceMembers {
  Some(ExtendedAttributeList, InterfaceMember, InterfaceMembers)
  None
}

///|
pub fn InterfaceMembers::iter(
  self : Self,
) -> Iter[(ExtendedAttributeList, InterfaceMember)] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(attribute_list, current_member, rest) => {
        target = rest

        Some((attribute_list, current_member))
      }
      None => None
    }
  })
}

///|
pub fn InterfaceMembers::parse(input : Tokens) -> (InterfaceMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    InterfaceMember::parse(after_extended_attribute_list)
    is Some((interface_member, after_interface_member)) &&
    InterfaceMembers::parse(after_interface_member) is (interface_members, rest) {
    return (
      InterfaceMembers::Some(
        extended_attribute_list, interface_member, interface_members,
      ),
      rest,
    )
  }

  (InterfaceMembers::None, input)
}

///|
pub struct InterfaceRest {
  identifier : StringView
  inheritance : Inheritance
  interface_members : InterfaceMembers
}

///|
pub fn InterfaceRest::parse(input : Tokens) -> (InterfaceRest, Tokens)? {
  if input is [(@lexer.TokenType::Identifier, identifier), .. after_identifier] &&
    Inheritance::parse(after_identifier)
    is (
      inheritance,
      [(@lexer.TokenType::Punctuation, "{"), .. after_interface_start],
    ) &&
    InterfaceMembers::parse(after_interface_start)
    is (
      interface_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (InterfaceRest::{ identifier, inheritance, interface_members, }, rest),
    )
  }

  None
}

///|
pub enum InterfaceOrMixin {
  InterfaceRest(InterfaceRest)
  MixinRest(MixinRest)
}

///|
pub fn InterfaceOrMixin::parse(input : Tokens) -> (InterfaceOrMixin, Tokens)? {
  if InterfaceRest::parse(input) is Some((interface_rest, rest)) {
    return Some((InterfaceOrMixin::InterfaceRest(interface_rest), rest))
  }

  if MixinRest::parse(input) is Some((mixin_rest, rest)) {
    return Some((InterfaceOrMixin::MixinRest(mixin_rest), rest))
  }

  None
}

///|
pub enum CallbackOrInterfaceOrMixin {
  Callback(CallbackRestOrInterface)
  Interface(InterfaceOrMixin)
}

///|
pub fn CallbackOrInterfaceOrMixin::parse(
  input : Tokens,
) -> (CallbackOrInterfaceOrMixin, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "callback"), .. after_callback] &&
    CallbackRestOrInterface::parse(after_callback)
    is Some((callback_rest_or_interface, rest)) {
    return Some(
      (CallbackOrInterfaceOrMixin::Callback(callback_rest_or_interface), rest),
    )
  }

  if input is [(@lexer.TokenType::Keyword, "interface"), .. after_interface] &&
    InterfaceOrMixin::parse(after_interface) is Some((interface_or_mixin, rest)) {
    return Some(
      (CallbackOrInterfaceOrMixin::Interface(interface_or_mixin), rest),
    )
  }

  None
}

///|
pub struct IncludesStatement {
  interface_identifier : StringView
  mixin_identifier : StringView
}

///|
pub fn IncludesStatement::parse(input : Tokens) -> (IncludesStatement, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, interface_identifier),
      (@lexer.TokenType::Keyword, "includes"),
      (@lexer.TokenType::Identifier, mixin_identifier),
      (@lexer.TokenType::Punctuation, ";"),
      .. rest,
    ] {
    return Some(
      (IncludesStatement::{ interface_identifier, mixin_identifier, }, rest),
    )
  }

  None
}

///|
pub enum Definition {
  CallbackOrInterfaceOrMixin(CallbackOrInterfaceOrMixin)
  Namespace(Namespace)
  Partial(Partial)
  Dictionary(Dictionary)
  Enum(Enum)
  Typedef(Typedef)
  IncludesStatement(IncludesStatement)
}

///|
pub fn Definition::parse(input : Tokens) -> (Definition, Tokens)? {
  if CallbackOrInterfaceOrMixin::parse(input)
    is Some((callback_or_interface_or_mixin, rest)) {
    return Some(
      (
        Definition::CallbackOrInterfaceOrMixin(callback_or_interface_or_mixin),
        rest,
      ),
    )
  }

  if Namespace::parse(input) is Some((namespace_, rest)) {
    return Some((Definition::Namespace(namespace_), rest))
  }

  if Partial::parse(input) is Some((partial, rest)) {
    return Some((Definition::Partial(partial), rest))
  }

  if Dictionary::parse(input) is Some((dictionary, rest)) {
    return Some((Definition::Dictionary(dictionary), rest))
  }

  if Enum::parse(input) is Some((enum_, rest)) {
    return Some((Definition::Enum(enum_), rest))
  }

  if Typedef::parse(input) is Some((typedef, rest)) {
    return Some((Definition::Typedef(typedef), rest))
  }

  if IncludesStatement::parse(input) is Some((includes_statement, rest)) {
    return Some((Definition::IncludesStatement(includes_statement), rest))
  }

  None
}

///|
pub enum Definitions {
  Some(ExtendedAttributeList, Definition, Definitions)
  None
}

///|
pub fn Definitions::iter(
  self : Self,
) -> Iter[(ExtendedAttributeList, Definition)] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(attribute_list, current_definition, rest) => {
        target = rest

        Some((attribute_list, current_definition))
      }
      None => None
    }
  })
}

///|
#as_free_fn(parse, visibility="pub")
pub fn Definitions::parse(input : Tokens) -> (Definitions, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    Definition::parse(after_extended_attribute_list)
    is Some((definition, after_definition)) &&
    Definitions::parse(after_definition) is (definitions, rest) {
    return (
      Definitions::Some(extended_attribute_list, definition, definitions),
      rest,
    )
  }

  (Definitions::None, input)
}
