use std::convert::TryInto;

pub struct Chunk {
    code: Vec<u8>,
    literals: Vec<Value>,
}

mod memory {
    pub fn to_u64(byte_array: &[u8; 8]) -> u64 {
        unsafe { std::mem::transmute::<[u8; 8], u64>(*byte_array) }.to_be()
    }

    pub fn to_u32(byte_array: &[u8; 4]) -> u32 {
        unsafe { std::mem::transmute::<[u8; 4], u32>(*byte_array) }.to_be()
    }
}

impl Chunk {
    pub fn new(code: Vec<u8>) -> Chunk {
        // Bytecode structure:
        // [length of literals as 4 bytes] [values of literals as tagged types]
        // [remaining bytecode]

        println!("{:?}", &code[0..4]);
        let lit_count = memory::to_u32(&code[0..4].try_into().unwrap());
        println!("literals in the code: {}", lit_count);

        let mut index = 4;
        let literals = if lit_count > 0 {
            let mut arr: Vec<Value> = Vec::with_capacity(lit_count as usize);
            let mut read_literals = 0;
            while read_literals < lit_count {
                match code[index] {
                    1 => {
                        index += 1;
                        let value = memory::to_u64(&code[index..(index + 8)].try_into().unwrap());
                        arr.push(Value {
                            value_type: Type::Integer,
                            data: ValueData { integer: value },
                        });
                        index += 8;
                        read_literals += 1;
                    }
                    _ => panic!("Unknown literal type found in code: {}", code[index]),
                }
            }
            arr
        } else {
            Vec::new()
        };

        Chunk {
            code: code[index..].to_owned(),
            literals: literals,
        }
    }
}

#[derive(Clone, Copy)]
enum Op {
    RETURN = 1,
    LOAD_LIT = 2,
}

impl Op {
    fn is(&self, byte: &u8) -> bool {
        *self as u8 == *byte
    }
}

pub struct VM<'a> {
    stack: Vec<&'a Value>,
    heap: Vec<Value>,
}

enum Type {
    Integer = 1,
}

struct Value {
    value_type: Type,
    data: ValueData,
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
        let mut result = String::from(name) + "\n";

        for (index, byte) in chunk.code.iter().enumerate() {
            let str = match byte {
                byte if Op::RETURN.is(byte) => {
                    format!("{:04} {:08}", index, "RETURN")
                }
                _ => panic!("Unknown opcode: {} at index {}", byte, index),
            };

            result += &str;
        }

        result
    }
}
