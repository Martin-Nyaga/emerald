use crate::vm::byte_reader;
use crate::vm::Value;
use std::result::Result;

pub const MAGIC: u32 = 0xFFFFFFFE;

#[derive(Default)]
pub struct Chunk {
    pub literals: Vec<Value>,
    pub bytecode: Vec<u8>,
}

impl Chunk {
    pub fn new() -> Self {
        Chunk::default()
    }

    pub fn from_bytecode(bytecode: Vec<u8>) -> Self {
        match chunk_parser::parse_chunk(bytecode) {
            Ok(chunk) => chunk,
            Err(e) => panic!("{}", e),
        }
    }

    pub fn to_bytecode(&self) -> Vec<u8> {
        chunk_parser::dump_chunk(self)
    }

    pub fn source_file_path(&self) -> &Value {
        &self.literals[0]
    }
}

mod chunk_parser {
    use super::*;
    use crate::vm::value::*;

    pub fn parse_chunk(bytecode: Vec<u8>) -> Result<Chunk, String> {
        BytecodeParser::new(bytecode).parse_chunk()
    }

    pub fn dump_chunk(chunk: &Chunk) -> Vec<u8> {
        let mut code = vec![];
        code.extend(MAGIC.to_be_bytes());
        code.extend((chunk.literals.len() as u32).to_be_bytes());
        for lit in &chunk.literals {
            code.extend(lit.to_bytes());
        }
        code.extend(&chunk.bytecode);
        code
    }

    struct BytecodeParser {
        bytecode: Vec<u8>,
        offset: usize,
    }

    impl BytecodeParser {
        pub fn new(bytecode: Vec<u8>) -> Self {
            BytecodeParser {
                bytecode,
                offset: 0,
            }
        }

        // Bytecode chunk structure
        //
        // magic: 4 bytes
        //   Magic beginning of chunk value
        //
        // literals: 4 byte length (u32); variable bytes data
        //   array of literals for the chunk. The first literal in the array must be the source
        //   file path of the file that produced the chunk
        //
        // bytecode: variable number of bytes
        //   the actual bytecode to be executed by the VM
        //
        // Literal layout
        //
        // Integer: 1 byte tag, 8 bytes of data
        // String: 1 byte tag, 8 bytes of size, variable number of bytes for data
        //
        pub fn parse_chunk(mut self) -> Result<Chunk, String> {
            self.read_magic()?;
            let literals = self.read_literals()?;

            let chunk = Chunk {
                literals,
                bytecode: self.bytecode[self.offset..].into(),
            };
            Ok(chunk)
        }

        fn current_u32(&self) -> Option<u32> {
            byte_reader::read_u32(&self.bytecode[self.offset..])
        }

        fn read_magic(&mut self) -> Result<(), String> {
            if let Some(MAGIC) = self.current_u32() {
                self.advance(4);
                Ok(())
            } else {
                Err("invalid bytecode: no magic byte at beginning of chunk".into())
            }
        }

        fn read_literals(&mut self) -> Result<Vec<Value>, String> {
            let size = self.current_u32().unwrap() as usize;
            self.advance(4);
            let mut literals = Vec::with_capacity(size);
            if size > 0 {
                for _ in 0..size {
                    literals.push(self.read_literal()?);
                }
            }
            Ok(literals)
        }

        fn read_literal(&mut self) -> Result<Value, String> {
            let (bytes_read, value) = Value::from_bytes(&self.bytecode[self.offset..])?;
            self.advance(bytes_read);
            Ok(value)
        }

        fn advance(&mut self, n: usize) {
            self.offset += n;
        }
    }
}
