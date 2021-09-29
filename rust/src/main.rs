mod vm;
use vm::chunk::Chunk;
use vm::value::Value;
use vm::VM;

fn example_bytecode() -> Vec<u8> {
    let mut chunk = Chunk::new();

    // Source file path
    chunk
        .literals
        .push(Value::String("test/file.emx".to_owned()));
    chunk.literals.push(Value::Integer(120));
    chunk.literals.push(Value::Integer(120));

    // Bytecode
    chunk.bytecode.extend([vm::Op::LoadLiteral as u8, 0]); // LoadLit 0
    chunk.bytecode.extend([vm::Op::Return as u8]);

    let code = chunk.to_bytecode();
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
    println!("{}", vm.disassemble(&Chunk::from_bytecode(bytes), "main"));
}
