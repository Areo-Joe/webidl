///|
pub struct CallbackRest {
  identifier : StringView
  type_ : Type
  argument_list : ArgumentList
}

///|
pub fn CallbackRest::parse(input : Tokens) -> (CallbackRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      .. after_equal,
    ] &&
    Type::parse(after_equal)
    is Some(
      (type_, [(@lexer.TokenType::Punctuation, "("), .. after_open_paren])
    ) &&
    ArgumentList::parse(after_open_paren)
    is (
      argument_list,
      [
        (@lexer.TokenType::Punctuation, ")"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((CallbackRest::{ identifier, type_, argument_list }, rest))
  }

  None
}

///|
pub enum CallbackInterfaceMember {
  Const(Const)
  RegularOperation(RegularOperation)
}

///|
pub fn CallbackInterfaceMember::parse(
  input : Tokens,
) -> (CallbackInterfaceMember, Tokens)? {
  if Const::parse(input) is Some((const_, rest)) {
    return Some((CallbackInterfaceMember::Const(const_), rest))
  }

  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some(
      (CallbackInterfaceMember::RegularOperation(regular_operation), rest),
    )
  }

  None
}

///|
pub enum CallbackInterfaceMembers {
  Some(ExtendedAttributeList, CallbackInterfaceMember, CallbackInterfaceMembers)
  None
}

///|
pub fn CallbackInterfaceMembers::parse(
  input : Tokens,
) -> (CallbackInterfaceMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    CallbackInterfaceMember::parse(after_extended_attribute_list)
    is Some((callback_interface_member, after_callback_interface_member)) &&
    CallbackInterfaceMembers::parse(after_callback_interface_member)
    is (callback_interface_members, rest) {
    return (
      CallbackInterfaceMembers::Some(
        extended_attribute_list, callback_interface_member, callback_interface_members,
      ),
      rest,
    )
  }

  (CallbackInterfaceMembers::None, input)
}

///|
pub enum CallbackRestOrInterface {
  CallbackRest(CallbackRest)
  Interface(StringView, CallbackInterfaceMembers)
}

///|
pub fn CallbackRestOrInterface::parse(
  input : Tokens,
) -> (CallbackRestOrInterface, Tokens)? {
  if CallbackRest::parse(input) is Some((callback_rest, rest)) {
    return Some((CallbackRestOrInterface::CallbackRest(callback_rest), rest))
  }

  if input
    is [
      (@lexer.TokenType::Keyword, "interface"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_interface_start,
    ] &&
    CallbackInterfaceMembers::parse(after_interface_start)
    is (
      callback_interface_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (
        CallbackRestOrInterface::Interface(
          identifier, callback_interface_members,
        ),
        rest,
      ),
    )
  }

  None
}
