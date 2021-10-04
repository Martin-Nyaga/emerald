pub mod file;
mod lexer;
mod parser;
mod sexp;

pub fn compile<'a, T>(file: &'a T)
where
    T: file::File<'a>,
{
    let tokens = lexer::tokenise(file);
    println!("{:#?}", tokens);

    let ast = parser::parse(file, &tokens);
    println!("{:#?}", ast);
}
