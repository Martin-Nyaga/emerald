pub mod file;
mod lexer;
mod sexp;

pub fn compile<'a, T>(file: &'a mut T)
where
    T: file::File<'a>,
{
    let tokens = lexer::tokenise(file);
    println!("{:#?}", tokens);
}
