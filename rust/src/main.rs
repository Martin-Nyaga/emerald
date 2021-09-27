mod vm;
use vm::chunk::Chunk;
use vm::VM;

fn example_bytecode() -> Vec<u8> {
    let mut code = vec![];

    // Magic
    code.extend(vm::chunk::MAGIC.to_be_bytes());

    // Source file
    let source_file_path = "test/file.emx";
    code.extend((source_file_path.len() as u16).to_be_bytes());
    code.extend(source_file_path.bytes().collect::<Vec<u8>>());

    // Line number array
    code.extend((0 as u32).to_be_bytes());

    // Literals
    code.extend((2 as u32).to_be_bytes());

    code.push(vm::value::Type::Integer as u8);
    code.extend((120 as u64).to_be_bytes());

    code.push(vm::value::Type::Integer as u8);
    code.extend((120 as u64).to_be_bytes());

    // Bytecode
    code.extend([vm::Op::LoadLiteral as u8, 0]); // LoadLit 0
    code.extend([vm::Op::Return as u8]);

    println!("Code: {:?}", code);
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
