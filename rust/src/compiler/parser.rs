use super::file;
use super::lexer;
use super::sexp::{s, t, Sexp};

pub fn parse<'file: 'tokens, 'tokens, T: file::File<'file>>(
    file: &'file T,
    tokens: &'tokens Vec<Sexp<'tokens, lexer::TokenType>>,
) -> Sexp<'tokens, Node> {
    Parser::new(file, tokens).parse().unwrap()
}

#[derive(Debug, Clone, Copy)]
pub enum Node {
    Args,
    Block,
    Call,
    Identifier,
    Integer,
}

struct Parser<'file: 'tokens, 'tokens, T> {
    file: &'file T,
    tokens: &'tokens Vec<Sexp<'tokens, lexer::TokenType>>,
    position: usize,
}

impl<'file: 'tokens, 'tokens, T: file::File<'file>> Parser<'file, 'tokens, T> {
    fn new(file: &'file T, tokens: &'tokens Vec<Sexp<'tokens, lexer::TokenType>>) -> Self {
        Parser {
            file,
            tokens,
            position: 0,
        }
    }

    fn parse(&mut self) -> Option<Sexp<'tokens, Node>> {
        let mut ast = s(Node::Block, vec![], self.position);

        while !self.at_end() {
            if let Some(node) = self.parse_expr() {
                ast.push(node).unwrap();
            } else {
                break;
            }
        }

        Some(ast)
    }

    fn parse_expr(&mut self) -> Option<Sexp<'tokens, Node>> {
        self.parse_call_expr()
            .or_else(|| self.parse_terminal_expr())
    }

    fn parse_call_expr(&mut self) -> Option<Sexp<'tokens, Node>> {
        if self.matches(lexer::TokenType::Identifier) {
            let ident = self.previous_token();
            let ident = t(
                Node::Identifier,
                ident.text_content().unwrap(),
                ident.offset(),
            );
            let offset = ident.offset();
            let args = self.parse_args_expr()?;
            let children = vec![ident, args];
            let result = Some(s(Node::Call, children, offset));
            return result;
        }
        None
    }

    fn parse_args_expr(&mut self) -> Option<Sexp<'tokens, Node>> {
        let mut node = s(Node::Args, vec![], self.current_token().offset());
        while !self.at_end() {
            if let Some(arg) = self.parse_terminal_expr() {
                node.push(arg).unwrap();
            } else {
                break;
            }
        }
        return Some(node);
    }

    fn parse_terminal_expr(&mut self) -> Option<Sexp<'tokens, Node>> {
        self.parse_integer_expr()
    }

    fn parse_integer_expr(&mut self) -> Option<Sexp<'tokens, Node>> {
        if self.matches(lexer::TokenType::Integer) {
            let integer = self.previous_token();
            return Some(t(
                Node::Integer,
                integer.text_content().unwrap(),
                integer.offset(),
            ));
        }
        None
    }

    fn matches(&mut self, token_type: lexer::TokenType) -> bool {
        if self.current_token().type_() == token_type {
            self.advance(1);
            true
        } else {
            false
        }
    }

    fn at_end(&self) -> bool {
        self.position == self.tokens.len()
    }

    fn previous_token(&self) -> &'tokens Sexp<'tokens, lexer::TokenType> {
        &self.tokens[self.position - 1]
    }

    fn current_token(&self) -> &'tokens Sexp<'tokens, lexer::TokenType> {
        &self.tokens[self.position]
    }

    fn advance(&mut self, n: usize) {
        self.position += n;
    }
}
