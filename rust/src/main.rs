mod vm;
use vm::{Chunk, VM};

fn example_bytecode() -> Vec<u8> {
    let mut code = vec![];

    // Constants
    code.push(0);
    code.push(1);

    code.push(1);
    code.extend((120 as u64).to_be_bytes());

    // Operations
    code.push(1);
    code.push(0);

    code.push(0);
    code
}

fn main() {
    // let path = std::env::args().nth(1).expect("filename must be provided");

    // println!("reading file: {}", path);
    // let bytes = std::fs::read(path).map_err(|e| format!("{}", e)).unwrap();
    let bytes = example_bytecode();

    println!("interpreting bytecode");
    let vm = VM::new();
    println!("{}", vm.disassemble(&Chunk::new(bytes), "main"));
}
