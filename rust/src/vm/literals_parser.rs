use crate::vm::value::*;
use std::convert::TryInto;

pub fn parse_literals(code: &Vec<u8>) -> (usize, Vec<Value>) {
    let mut literals_parser = LiteralsParser::new(code);
    let literals = literals_parser.read_literals();
    let offset = literals_parser.offset;
    (offset, literals)
}

struct LiteralsParser<'a> {
    pub literal_count: u16,
    pub offset: usize,
    code: &'a Vec<u8>,
}

impl<'a> LiteralsParser<'a> {
    pub fn new(code: &'a Vec<u8>) -> Self {
        LiteralsParser {
            literal_count: 0,
            offset: 0,
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
        self.offset += 2;
    }

    fn read_literal(&mut self) -> Value {
        match self.code[self.offset] {
            byte if byte == Type::Integer as u8 => self.read_integer(),
            _ => panic!(
                "Unknown literal type found in code: {}",
                self.code[self.offset]
            ),
        }
    }

    fn read_integer(&mut self) -> Value {
        self.offset += 1;
        let integer = u64::from_be_bytes(
            self.code[self.offset..(self.offset + 8)]
                .try_into()
                .unwrap(),
        );
        let value = Value {
            type_: Type::Integer,
            data: ValueData { integer },
        };
        self.offset += 8;
        value
    }
}
