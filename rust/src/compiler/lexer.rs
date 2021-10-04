use super::file;
use super::sexp::{s, t, Sexp};
use std::slice::Iter;

use regex::Regex;

pub fn tokenise<'a, F>(file: &'a F) -> Vec<Sexp<'a, TokenType>>
where
    F: file::File<'a>,
{
    Lexer::new(file.contents()).tokenise()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum TokenType {
    Integer,
    Space,
    Newline,
    Identifier,
}

impl TokenType {
    fn iter() -> Iter<'static, TokenType> {
        static TOKEN_TYPES: [TokenType; 4] = [
            TokenType::Integer,
            TokenType::Space,
            TokenType::Newline,
            TokenType::Identifier,
        ];
        TOKEN_TYPES.iter()
    }

    fn skip(&self) -> bool {
        match self {
            TokenType::Space => true,
            _ => false,
        }
    }

    fn regex(&self) -> Regex {
        match self {
            TokenType::Integer => Regex::new(r"\A[0-9]+"),
            TokenType::Space => Regex::new(r"\A[ \t]+"),
            TokenType::Newline => Regex::new(r"\A\n|\A\r\n"),
            TokenType::Identifier => {
                Regex::new(r"\A[+\-\\/*%]|\A[><]=?|\A==|\A[a-z]+[a-zA-Z_0-9]*\??")
            }
        }
        .unwrap()
    }

    fn matches<'a>(&self, text: &'a str, offset: usize) -> Option<Match<'a>> {
        let match_ = self.regex().find(&text[offset..])?;
        Some(Match::new(*self, match_.as_str(), offset))
    }
}

struct Match<'a> {
    token_type: TokenType,
    text: &'a str,
    offset: usize,
}

impl<'a> Match<'a> {
    fn new(token_type: TokenType, text: &'a str, offset: usize) -> Match<'a> {
        Match {
            token_type,
            text,
            offset,
        }
    }

    fn len(&self) -> usize {
        self.text.len()
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

    fn tokenise(&mut self) -> Vec<Sexp<'a, TokenType>> {
        let mut result = vec![];

        while !self.at_end() {
            if let Some(match_) = self.sorted_matches().pop() {
                self.offset += match_.len();
                if !match_.token_type.skip() {
                    result.push(t(match_.token_type, match_.text, match_.offset));
                }
            } else {
                panic!("Couldn't parse source!");
            }
        }

        result
    }

    fn sorted_matches(&self) -> Vec<Match<'a>> {
        let mut matches: Vec<Match<'a>> = TokenType::iter()
            .filter_map(|t| t.matches(&self.source, self.offset))
            .collect();
        matches.sort_by(|a, b| a.len().cmp(&b.len()));
        matches
    }

    fn at_end(&self) -> bool {
        self.offset == self.source.len()
    }
}
