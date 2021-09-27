use crate::vm::Value;
use std::result::Result;

pub const MAGIC: u32 = 0xFFFFFFFE;

pub struct Chunk {
    pub code: Vec<u8>,
    pub literals: Vec<Value>,
    pub source_file_path: String,
    pub line_numbers: Vec<u32>,
}

impl Chunk {
    pub fn new(code: Vec<u8>) -> Chunk {
        match bytecode_parser::parse_chunk(code) {
            Ok(chunk) => chunk,
            Err(e) => panic!(e),
        }
    }
}

mod bytecode_parser {
    use super::*;
    use crate::vm::value::*;
    use std::convert::TryInto;

    pub fn parse_chunk(code: Vec<u8>) -> Result<Chunk, String> {
        BytecodeParser::new(code).parse_chunk()
    }

    struct BytecodeParser {
        code: Vec<u8>,
        offset: usize,
    }

    impl BytecodeParser {
        pub fn new(code: Vec<u8>) -> Self {
            BytecodeParser { code, offset: 0 }
        }

        // Bytecode chunk structure:
        //
        // [Magic beginning of chunk value: 4 bytes]
        // [Source file path string length: 2 bytes]
        // [Source file path: variable number of bytes]
        // [Line number array length: 4 bytes]
        // [Line number array: variable number of bytes, [ip: 4 bytes, line number: 4 bytes]]
        // [Literal array length: 4 bytes]
        // [Literal array: variable number of bytes: [tagged Values]]
        //
        // [bytecode: variable number of bytes]
        pub fn parse_chunk(mut self) -> Result<Chunk, String> {
            self.read_magic()?;
            let source_file_path = self.read_source_file_path()?;
            let line_numbers = self.read_line_number_array()?;
            let literals = self.read_literals()?;

            let chunk = Chunk {
                code: self.code[self.offset..].into(),
                literals: literals,
                source_file_path: source_file_path,
                line_numbers: line_numbers,
            };
            Ok(chunk)
        }

        fn current_byte(&self) -> u8 {
            self.code[self.offset]
        }

        fn current_u32(&self) -> u32 {
            u32::from_be_bytes(self.code[self.offset..self.offset + 4].try_into().unwrap())
        }

        fn current_u16(&self) -> u16 {
            u16::from_be_bytes(self.code[self.offset..self.offset + 2].try_into().unwrap())
        }

        fn current_u64(&self) -> u64 {
            u64::from_be_bytes(
                self.code[self.offset..(self.offset + 8)]
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

        fn read_source_file_path(&mut self) -> Result<String, String> {
            let size = self.current_u16() as usize;
            self.advance(2);
            let source_file_path =
                std::str::from_utf8(&self.code[self.offset..self.offset + size as usize])
                    .map_err(|_| "invalid bytecode: failed to read source_file_path")?
                    .to_owned();
            self.advance(size);
            Ok(source_file_path)
        }

        fn read_line_number_array(&mut self) -> Result<Vec<u32>, String> {
            let size = self.current_u32() as usize;
            self.advance(4);
            let mut line_number_array = Vec::with_capacity(size);
            for _ in 0..size {
                line_number_array.push(self.current_u32());
                self.advance(4);
            }
            Ok(line_number_array)
        }

        pub fn read_literals(&mut self) -> Result<Vec<Value>, String> {
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
                _ => Err(format!(
                    "Unknown literal type found in code: {}",
                    self.code[self.offset]
                )),
            }
        }

        fn read_integer(&mut self) -> Result<Value, String> {
            self.advance(1); // tag
            let integer = self.current_u64();
            let value = Value {
                type_: Type::Integer,
                data: ValueData { integer },
            };
            self.advance(8); // u64
            Ok(value)
        }

        fn advance(&mut self, n: usize) {
            self.offset += n;
        }
    }
}
