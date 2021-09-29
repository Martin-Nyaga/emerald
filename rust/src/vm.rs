pub mod byte_reader;
pub mod chunk;
mod disassembler;
pub mod value;

use chunk::*;
use value::*;

use std::convert::TryFrom;
use std::convert::TryInto;

#[derive(Clone, Copy, Debug)]
#[repr(u8)]
pub enum Op {
    Return = 0,
    LoadLiteral,
    Add,
}

pub const MAX_INSTRUCTION_ARGS_COUNT: usize = 3;

impl TryFrom<u8> for Op {
    type Error = String;

    fn try_from(byte: u8) -> Result<Self, Self::Error> {
        match byte {
            0x0 => Ok(Op::Return),
            0x1 => Ok(Op::LoadLiteral),
            0x2 => Ok(Op::Add),
            _ => Err(format!("Invalid instruction: {}", byte)),
        }
    }
}

#[derive(Debug)]
pub enum Error {
    RuntimeError(String),
}

#[derive(Default)]
pub struct VM {
    stack: Vec<Value>,
    // heap: Vec<Value>,
    chunk: Chunk,
    ip: usize,
}

impl VM {
    pub fn new() -> VM {
        VM::default()
    }

    pub fn interprete(&mut self, chunk: Chunk) -> Result<(), Error> {
        self.chunk = chunk;
        self.ip = 0;
        self.run()
    }

    fn run(&mut self) -> Result<(), Error> {
        loop {
            let byte = self.read_byte();
            let op: Op = byte.try_into().map_err(|s| Error::RuntimeError(s))?;

            // Debug stack
            println!("{:?}", self.stack);
            match op {
                Op::Return => return Ok(()),
                Op::LoadLiteral => {
                    let index = self.read_u32().ok_or(Error::RuntimeError(
                        "could not read literal index".to_string(),
                    ))?;
                    let _line = self.read_u32();
                    let literal = self.chunk.literals[index as usize].clone();
                    self.stack.push(literal);
                }
                Op::Add => {
                    let a = self.stack.pop();
                    if let Some(Value::Integer(a)) = a {
                        let b = self.stack.pop();
                        if let Some(Value::Integer(b)) = b {
                            self.stack.push(Value::Integer(a + b));
                        } else {
                            return Err(Error::RuntimeError(format!(
                                "invalid type {:?} for add",
                                b
                            )));
                        }
                    } else {
                        return Err(Error::RuntimeError(format!("invalid type {:?} for add", a)));
                    }
                }
            };
        }
    }

    fn read_byte(&mut self) -> u8 {
        let byte = self.chunk.bytecode[self.ip];
        self.ip += 1;
        byte
    }

    fn read_u32(&mut self) -> Option<u32> {
        if let Some(num) = byte_reader::read_u32(&self.chunk.bytecode[self.ip..]) {
            self.ip += 4;
            return Some(num);
        } else {
            return None;
        }
    }

    // fn peek_byte(&mut self) -> u8 {
    //     self.chunk.bytecode[self.ip]
    // }

    pub fn disassemble(&self, chunk: &Chunk, name: &'static str) -> String {
        disassembler::disassemble_chunk(&chunk, name)
    }
}
