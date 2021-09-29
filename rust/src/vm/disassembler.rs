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
            let op: Op = byte.try_into().unwrap();
            result += &match op {
                Op::Return => self.disassemble_instruction("Return", 0),
                Op::LoadLiteral => self.disassemble_instruction("LoadLit", 1),
                Op::Add => self.disassemble_instruction("Add", 0),
            };
        }
        result + "\n"
    }

    fn disassemble_instruction(&mut self, instruction: &'static str, args_count: usize) -> String {
        // Instruction
        let mut text = format!("  {:04} {:08}", self.ip, instruction);
        self.ip += 1;

        // Arguments
        for _ in 0..args_count {
            text += &format!(
                " {:04}",
                byte_reader::read_u32(&self.chunk.bytecode[self.ip..]).unwrap()
            );
            self.ip += 4;
        }

        // Padding
        for _ in 0..(MAX_INSTRUCTION_ARGS_COUNT - args_count) {
            text += &format!(" {:04}", "");
        }

        // Offset
        text += &format!(
            " <{:04}>",
            byte_reader::read_u32(&self.chunk.bytecode[self.ip..]).unwrap()
        );
        self.ip += 4;
        text + "\n"
    }
}

pub fn disassemble_chunk(chunk: &Chunk, chunk_name: &'static str) -> String {
    Disassembler::new(chunk, chunk_name).disassemble()
}
