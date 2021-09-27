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
        result += &self.disassemble_literals();
        result += &self.disassemble_instructions();
        result
    }

    fn disassemble_literals(&mut self) -> String {
        let mut result = format!("{}.data:\n", self.chunk_name);
        for (index, lit) in self.chunk.literals.iter().enumerate() {
            result += &format!("  {:04} {}\n", index, lit);
        }
        result + "\n"
    }

    fn disassemble_instructions(&mut self) -> String {
        let mut result = format!("{}.code:\n", self.chunk_name);
        while self.ip < self.chunk.bytecode.len() {
            let byte = self.chunk.bytecode[self.ip];
            result += &match byte {
                byte if byte == Op::Return as u8 => self.disassemble_instruction("Return", 0),
                byte if byte == Op::LoadLiteral as u8 => self.disassemble_instruction("LoadLit", 1),
                _ => panic!("Unknown opcode: {} at offset {}", byte, self.ip),
            };
        }
        result + "\n"
    }

    fn disassemble_instruction(&mut self, instruction: &'static str, args_count: usize) -> String {
        let mut text = format!("  {:04} {:08}", self.ip, instruction);
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
