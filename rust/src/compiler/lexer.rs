use super::file;
use super::sexp::{s, t, Sexp};
use std::slice::Iter;

use regex::Regex;

pub fn tokenise<'a, F>(file: &'a mut F) -> Vec<Sexp<'a, TokenType>>
where
    F: file::File<'a>,
{
    Lexer::new(file.contents()).tokenise()
}

#[derive(Debug)]
pub enum TokenType {
    Integer,
    Space,
    Newline,
}

impl TokenType {
    pub fn iter() -> Iter<'static, TokenType> {
        static TOKEN_TYPES: [TokenType; 3] =
            [TokenType::Integer, TokenType::Space, TokenType::Newline];
        TOKEN_TYPES.iter()
    }

    pub fn matches<'a>(&self, text: &'a str, offset: usize) -> Option<Sexp<'a, TokenType>> {
        match self {
            TokenType::Integer => self.matches_with(TokenType::Integer, text, offset, r"\A[0-9]+"),
            TokenType::Space => self.matches_with(TokenType::Space, text, offset, r"\A[ \t]+"),
            TokenType::Newline => {
                self.matches_with(TokenType::Newline, text, offset, r"\A\n|\A\r\n")
            }
        }
    }

    fn matches_with<'a>(
        &self,
        type_: Self,
        text: &'a str,
        offset: usize,
        matcher: &'static str,
    ) -> Option<Sexp<'a, TokenType>> {
        let mut re: Regex = Regex::new(matcher).unwrap();
        let match_ = re.find(&text[offset..])?;
        Some(t(type_, match_.as_str(), offset))
    }
}

struct Lexer<'a> {
    source: &'a str,
    offset: usize,
}

impl<'a> Lexer<'a> {
    fn new(source: &'a str) -> Self {
        Lexer { source, offset: 0 }
    }

    pub fn tokenise(&mut self) -> Vec<Sexp<'a, TokenType>> {
        let mut result = vec![];

        while !self.at_end() {
            if let Some(token) = self.sorted_matches().pop() {
                self.offset += token.len();
                result.push(token);
            } else {
                panic!("Couldn't parse source!");
            }
        }

        result
    }

    fn sorted_matches(&self) -> Vec<Sexp<'a, TokenType>> {
        let mut matches = TokenType::iter()
            .map(|t| t.matches(&self.source, self.offset))
            .filter(|t| t.is_some())
            .map(|t| t.unwrap())
            .collect::<Vec<Sexp<'a, TokenType>>>();
        matches.sort_by(|a, b| a.len().cmp(&b.len()));
        matches
    }

    fn at_end(&self) -> bool {
        self.offset == self.source.len()
    }
}
