use crate::vm::Value;
use std::result::Result;

pub const MAGIC: u32 = 0xFFFFFFFE;

pub struct Chunk {
    pub literals: Vec<Value>,
    pub bytecode: Vec<u8>,
}

impl Chunk {
    pub fn new(bytecode: Vec<u8>) -> Chunk {
        match bytecode_parser::parse_chunk(bytecode) {
            Ok(chunk) => chunk,
            Err(e) => panic!("{}", e),
        }
    }

    pub fn source_file_path(&self) -> &Value {
        &self.literals[0]
    }
}

mod bytecode_parser {
    use super::*;
    use crate::vm::value::*;
    use std::convert::TryInto;

    pub fn parse_chunk(bytecode: Vec<u8>) -> Result<Chunk, String> {
        BytecodeParser::new(bytecode).parse_chunk()
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

        fn current_byte(&self) -> u8 {
            self.bytecode[self.offset]
        }

        fn current_u32(&self) -> u32 {
            u32::from_be_bytes(
                self.bytecode[self.offset..self.offset + 4]
                    .try_into()
                    .unwrap(),
            )
        }

        fn current_u16(&self) -> u16 {
            u16::from_be_bytes(
                self.bytecode[self.offset..self.offset + 2]
                    .try_into()
                    .unwrap(),
            )
        }

        fn current_u64(&self) -> u64 {
            u64::from_be_bytes(
                self.bytecode[self.offset..(self.offset + 8)]
                    .try_into()
                    .unwrap(),
            )
        }

        fn read_magic(&mut self) -> Result<(), String> {
            if self.current_u32() == MAGIC {
                self.advance(4);
                Ok(())
            } else {
                Err("invalid bytecode: no magic byte at beginning of chunk".into())
            }
        }

        fn read_literals(&mut self) -> Result<Vec<Value>, String> {
            let size = self.current_u32() as usize;
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
            match self.current_byte() {
                byte if byte == Type::Integer as u8 => self.read_integer(),
                byte if byte == Type::String as u8 => self.read_string(),
                _ => Err(format!(
                    "Unknown literal type found in bytecode: {}",
                    self.bytecode[self.offset]
                )),
            }
        }

        fn read_integer(&mut self) -> Result<Value, String> {
            self.advance(1); // tag
            let value = Value::Integer(self.current_u64());
            self.advance(8); // u64
            Ok(value)
        }

        fn read_string(&mut self) -> Result<Value, String> {
            self.advance(1); // tag
            let size = self.current_u64() as usize;
            self.advance(8); // u64: size
            let string = std::str::from_utf8(&self.bytecode[self.offset..self.offset + size])
                .map_err(|_| "failed to read string")?;
            let value = Value::String(string.to_owned());
            self.advance(size); // string data
            Ok(value)
        }

        fn advance(&mut self, n: usize) {
            self.offset += n;
        }
    }
}
