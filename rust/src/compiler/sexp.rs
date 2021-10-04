use std::fmt::{Debug, Error, Formatter};
use std::result::Result;

pub enum Sexp<'a, T> {
    Terminal(Terminal<'a, T>),
    NonTerminal(NonTerminal<'a, T>),
}

impl<'a, T: Debug + Copy> Sexp<'a, T> {
    pub fn len(&'a self) -> usize {
        match self {
            Sexp::Terminal(terminal) => terminal.contents.len(),
            Sexp::NonTerminal(non_terminal) => non_terminal
                .contents
                .iter()
                .fold(0, |acc, sexp| acc + sexp.len()),
        }
    }

    pub fn text_content(&self) -> Option<&str> {
        match self {
            Sexp::Terminal(terminal) => Some(terminal.contents),
            Sexp::NonTerminal(non_terminal) => None,
        }
    }

    pub fn offset(&self) -> usize {
        match self {
            Sexp::Terminal(terminal) => terminal.offset,
            Sexp::NonTerminal(non_terminal) => non_terminal.offset,
        }
    }

    pub fn type_(&self) -> T {
        match self {
            Sexp::Terminal(terminal) => terminal.type_,
            Sexp::NonTerminal(non_terminal) => non_terminal.type_,
        }
    }

    pub fn push(&mut self, value: Sexp<'a, T>) -> Result<(), ()> {
        match self {
            Sexp::Terminal(_) => Err(()),
            Sexp::NonTerminal(non_terminal) => {
                non_terminal.contents.push(value);
                Ok(())
            }
        }
    }
}

impl<'a, T: Debug> Debug for Sexp<'a, T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), Error> {
        match self {
            Sexp::Terminal(terminal) => terminal.fmt(f),
            Sexp::NonTerminal(non_terminal) => non_terminal.fmt(f),
        }
    }
}

pub struct Terminal<'a, T> {
    pub type_: T,
    pub contents: &'a str,
    pub offset: usize,
}

impl<'a, T: Debug> Debug for Terminal<'a, T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), Error> {
        f.write_str("s(")?;
        self.type_.fmt(f)?;
        f.write_str(", ")?;
        self.contents.fmt(f)?;
        f.write_str(", offset: ")?;
        self.offset.fmt(f)?;
        f.write_str(")")
    }
}

pub struct NonTerminal<'a, T> {
    pub type_: T,
    pub contents: Box<Vec<Sexp<'a, T>>>,
    pub offset: usize,
}

impl<'a, T: Debug> Debug for NonTerminal<'a, T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), Error> {
        f.write_str("s(")?;
        self.type_.fmt(f)?;
        f.write_str(", ")?;
        self.contents.fmt(f)?;
        f.write_str(", offset: ")?;
        self.offset.fmt(f)?;
        f.write_str(")")
    }
}

pub fn s<T: Debug>(type_: T, contents: Vec<Sexp<T>>, offset: usize) -> Sexp<T> {
    Sexp::NonTerminal(NonTerminal {
        type_,
        contents: Box::new(contents),
        offset,
    })
}

pub fn t<T: Debug>(type_: T, contents: &str, offset: usize) -> Sexp<T> {
    Sexp::Terminal(Terminal {
        type_,
        contents,
        offset,
    })
}
