///|
const INTEGER = re"^-?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)"

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
  Keyword
  String
  Punctuation
  Other
} derive(Debug)

///|
pub extend TokenType with @debug.Debug::{to_repr}

///|
pub fn tokenize(input : StringView) -> Array[(TokenType, StringView)] raise {
  let ret = []

  let scanner = @lexbuf.StringScanner::{ data: input, cursor: 0, }
  while scanner.cursor < input.length() {
    lexscan scanner {
      WHITESPACE => continue
      COMMENT => continue
      _ => ()
    }

    lexscan scanner with longest {
      INTEGER as t => {
        ret.push((Integer, t))
        continue
      }
      DECIMAL as t => {
        ret.push((Decimal, t))
        continue
      }
      IDENTIFIER as t => {
        let kind = if is_keyword(t) { TokenType::Keyword } else { Identifier }
        ret.push((kind, t))
        continue
      }
      STRING as t => {
        ret.push((String, t))
        continue
      }
      _ => {
        let curr = input[scanner.cursor:]
        let punctuation_length = match_punctuation(curr)
        if punctuation_length > 0 {
          ret.push((Punctuation, curr[:punctuation_length]))
          scanner.cursor += punctuation_length
          continue
        }
        guard OTHER.execute(curr) is Some(other) else {
          fail("nothing matched")
        }
        ret.push((Other, other.content()))
        scanner.cursor += other.content().length()
        continue
      }
    }
  }

  ret
}
