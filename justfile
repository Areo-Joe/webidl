# Fetch the WebIDL specification and regenerate lexer literal tables.
generate-literals:
  moon run cmd/build && moon fmt
