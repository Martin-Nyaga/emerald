mod vm;
use vm::{Chunk, VM};

fn main() {
    let path = std::env::args().nth(1).expect("filename must be provided");

    println!("reading file: {}", path);
    let bytes = std::fs::read(path).map_err(|e| format!("{}", e)).unwrap();

    println!("interpreting bytecode");
    let vm = VM::new();
    println!("{}", vm.disassemble(&Chunk::new(bytes), "main"));
}
