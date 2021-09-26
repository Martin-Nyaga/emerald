use std::convert::TryInto;

pub struct Chunk {
    code: Vec<u8>,
    literals: Vec<Value>,
}

mod memory {
    // Convert from byte arrays to unsigned integers. Big endian byte order assumed.
    pub fn to_u64(byte_array: &[u8; 8]) -> u64 {
        ((byte_array[0] as u64) << 56)
            | ((byte_array[1] as u64) << 48)
            | ((byte_array[2] as u64) << 40)
            | ((byte_array[3] as u64) << 32)
            | ((byte_array[4] as u64) << 24)
            | ((byte_array[5] as u64) << 16)
            | ((byte_array[6] as u64) << 8)
            | ((byte_array[7] as u64) << 0)
    }

    pub fn to_u32(byte_array: &[u8; 4]) -> u32 {
        ((byte_array[0] as u32) << 24)
            | ((byte_array[1] as u32) << 16)
            | ((byte_array[2] as u32) << 8)
            | ((byte_array[3] as u32) << 0)
    }

    pub fn to_u16(byte_array: &[u8; 2]) -> u16 {
        ((byte_array[0] as u16) << 8) | ((byte_array[1] as u16) << 0)
    }
}

struct LiteralsParser<'a> {
    pub literal_count: u16,
    pub index: usize,
    code: &'a Vec<u8>,
}

impl<'a> LiteralsParser<'a> {
    pub fn new(code: &'a Vec<u8>) -> Self {
        LiteralsParser {
            literal_count: 0,
            index: 0,
            code,
        }
    }

    pub fn read_literals(&mut self) -> Vec<Value> {
        self.read_literal_count();
        let mut literals: Vec<Value> = Vec::with_capacity(self.literal_count as usize);
        for _ in 0..self.literal_count {
            literals.push(self.read_literal());
        }
        literals
    }

    fn read_literal_count(&mut self) {
        self.literal_count = memory::to_u16(&self.code[0..2].try_into().unwrap());
        self.index += 2;
    }

    fn read_literal(&mut self) -> Value {
        match self.code[self.index] {
            byte if byte == Type::Integer as u8 => self.read_integer(),
            _ => panic!(
                "Unknown literal type found in code: {}",
                self.code[self.index]
            ),
        }
    }

    fn read_integer(&mut self) -> Value {
        self.index += 1;
        let integer = memory::to_u64(&self.code[self.index..(self.index + 8)].try_into().unwrap());
        let value = Value {
            value_type: Type::Integer,
            data: ValueData { integer },
        };
        self.index += 8;
        value
    }
}

impl Chunk {
    pub fn new(code: Vec<u8>) -> Chunk {
        // Bytecode structure:
        // [length of literals as 2 bytes (u16)]
        // [values of literals as tagged types]
        // [remaining bytecode]

        let mut literals_parser = LiteralsParser::new(&code);
        let literals = literals_parser.read_literals();
        let code_index = literals_parser.index;

        Chunk {
            code: code[code_index..].to_vec(),
            literals: literals,
        }
    }
}

#[derive(Clone, Copy)]
#[repr(u8)]
enum Op {
    Return = 0,
    LoadLiteral,
}

pub struct VM<'a> {
    stack: Vec<&'a Value>,
    heap: Vec<Value>,
}

#[derive(Clone, Copy, Debug)]
enum Type {
    Integer = 1,
}

struct Value {
    value_type: Type,
    data: ValueData,
}

impl std::fmt::Debug for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.value_type {
            Type::Integer => f
                .debug_struct("Value")
                .field("type", &self.value_type)
                .field("data", unsafe { &self.data.integer })
                .finish(),
        }
    }
}

union ValueData {
    integer: u64,
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

    pub fn disassemble(&self, chunk: Chunk, name: &str) -> String {
        disassembler::disassemble_chunk(chunk, name)
    }
}

mod disassembler {
    use super::*;

    pub fn disassemble_chunk(chunk: Chunk, name: &str) -> String {
        let mut result = format!("-- {} --\n", name);

        let mut index = 0;
        while index < chunk.code.len() {
            let byte = chunk.code[index];
            let str = match byte {
                byte if byte == Op::Return as u8 => {
                    let instruction = format!("{:04} {:08}\n", index, "Return");
                    index += 1;
                    instruction
                }
                byte if byte == Op::LoadLiteral as u8 => {
                    let instruction = format!(
                        "{:04} {:08} {:04}\n",
                        index,
                        "LoadLit",
                        chunk.code[index + 1]
                    );
                    index += 2;
                    instruction
                }
                _ => panic!("Unknown opcode: {} at index {}", byte, index),
            };

            result += &str;
        }

        result
    }
}
