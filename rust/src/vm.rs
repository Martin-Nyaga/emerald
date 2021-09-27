use std::convert::TryInto;

pub struct Chunk {
    code: Vec<u8>,
    literals: Vec<Value>,
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
        self.literal_count = u16::from_be_bytes(self.code[0..2].try_into().unwrap());
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
        let integer =
            u64::from_be_bytes(self.code[self.index..(self.index + 8)].try_into().unwrap());
        let value = Value {
            type_: Type::Integer,
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
    type_: Type,
    data: ValueData,
}

impl std::fmt::Debug for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.type_ {
            Type::Integer => f
                .debug_struct("Value")
                .field("type", &self.type_)
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

    pub fn disassemble(&self, chunk: &Chunk, name: &'static str) -> String {
        disassembler::disassemble_chunk(&chunk, name)
    }
}

mod disassembler {
    use super::*;

    struct Disassembler<'a> {
        chunk: &'a Chunk,
        chunk_name: &'static str,
        ip: usize,
    }

    impl<'a> Disassembler<'a> {
        pub fn new(chunk: &'a Chunk, chunk_name: &'static str) -> Self {
            Disassembler {
                ip: 0,
                chunk_name,
                chunk,
            }
        }

        fn disassemble(mut self) -> String {
            let mut result = format!("-- {} --\n", self.chunk_name);

            while self.ip < self.chunk.code.len() {
                let byte = self.chunk.code[self.ip];
                result += &match byte {
                    byte if byte == Op::Return as u8 => self.disassemble_instruction("Return", 0),
                    byte if byte == Op::LoadLiteral as u8 => {
                        self.disassemble_instruction("LoadLit", 1)
                    }
                    _ => panic!("Unknown opcode: {} at index {}", byte, self.ip),
                };
            }

            result
        }

        fn disassemble_instruction(
            &mut self,
            instruction: &'static str,
            args_count: usize,
        ) -> String {
            let mut text = format!("{:04} {:08}", self.ip, instruction);
            for i in 0..args_count {
                text += &format!(" {:04}", self.ip + i);
            }
            self.ip += self.ip + 1;
            text + "\n"
        }
    }

    pub fn disassemble_chunk(chunk: &Chunk, chunk_name: &'static str) -> String {
        Disassembler::new(chunk, chunk_name).disassemble()
    }
}
