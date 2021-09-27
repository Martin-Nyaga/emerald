pub mod chunk;
mod disassembler;
pub mod value;

use chunk::*;
use value::*;

#[derive(Clone, Copy)]
#[repr(u8)]
pub enum Op {
    Return = 0,
    LoadLiteral,
}

pub struct VM<'a> {
    stack: Vec<&'a Value>,
    heap: Vec<Value>,
}

impl<'a> VM<'a> {
    pub fn new() -> VM<'a> {
        VM {
            stack: Vec::new(),
            heap: Vec::new(),
        }
    }

    pub fn interprete(&mut self, chunk: Chunk) -> () {
        for byte in chunk.code {
            println!("Found byte: {}", byte);
        }
    }

    pub fn disassemble(&self, chunk: &Chunk, name: &'static str) -> String {
        disassembler::disassemble_chunk(&chunk, name)
    }
}
