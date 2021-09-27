use crate::vm::literals_parser;
use crate::vm::Value;

pub struct Chunk {
    pub code: Vec<u8>,
    pub literals: Vec<Value>,
}

impl Chunk {
    pub fn new(code: Vec<u8>) -> Chunk {
        // Bytecode structure:
        // [length of literals as 2 bytes (u16)]
        // [values of literals as tagged types]
        // [remaining bytecode]

        let (code_start_offset, literals) = literals_parser::parse_literals(&code);
        Chunk {
            code: code[code_start_offset..].to_vec(),
            literals: literals,
        }
    }
}
