///|
const INTEGER = re"^/?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)"

///|
const DECIMAL = re"^-?(([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+\-]?[0-9]+)?|[0-9]+[Ee][+\-]?[0-9]+)"

///|
const IDENTIFIER = re"^[_\-]?[A-Za-z][0-9A-Z_a-z\-]*"

///|
const STRING = re"^\"[^\"]*\""

///|
const WHITESPACE = re"^[\t\n\r ]+"

///|
const COMMENT = re"^(//[^\n]*|/\*.*?\*/)"

///|
const OTHER = re"^[^\t\n\r 0-9A-Za-z]"

///|
pub enum TokenType {
  Integer
  Decimal
  Identifier
  String
  Other
} derive(Debug)

///|
pub fn tokenize(input : StringView) -> Array[(TokenType, StringView)] raise {
  let ret = []

  for curr = input {
    lexscan curr {
      (WHITESPACE, after=after) => continue after
      (COMMENT, after=after) => continue after
      _ => ()
    }

    lexscan curr with longest {
      (INTEGER as t, after=after) => {
        ret.push((TokenType::Integer, t))
        continue after
      }
      (DECIMAL as t, after=after) => {
        ret.push((TokenType::Decimal, t))
        continue after
      }
      (IDENTIFIER as t, after=after) => {
        ret.push((TokenType::Identifier, t))
        continue after
      }
      (STRING as t, after=after) => {
        ret.push((TokenType::String, t))
        continue after
      }
      _ =>
        if curr.length() == 0 {
          break
        } else {
          guard OTHER.execute(curr) is Some(other) else {
            fail("nothing matched")
          }
          ret.push((TokenType::Other, other.content()))
          continue other.after()
        }
    }
  }

  ret
}
