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
    chunk.literals.push(Value::Integer(130));

    // Bytecode
    // [instruction, ...args, offset]
    chunk.bytecode.push(vm::Op::LoadLiteral as u8);
    chunk.bytecode.extend((1 as u32).to_be_bytes());
    chunk.bytecode.extend((0 as u32).to_be_bytes());

    chunk.bytecode.push(vm::Op::LoadLiteral as u8);
    chunk.bytecode.extend((2 as u32).to_be_bytes());
    chunk.bytecode.extend((0 as u32).to_be_bytes());

    chunk.bytecode.push(vm::Op::Add as u8);
    chunk.bytecode.extend((0 as u32).to_be_bytes());

    chunk.bytecode.push(vm::Op::Return as u8);
    chunk.bytecode.extend((1 as u32).to_be_bytes());

    let code = chunk.to_bytecode();
    code
}

fn main() {
    // let path = std::env::args().nth(1).expect("filename must be provided");

    // println!("reading file: {}", path);
    // let bytes = std::fs::read(path).map_err(|e| format!("{}", e)).unwrap();
    let bytes = example_bytecode();
    let chunk = Chunk::from_bytecode(bytes);
    let mut vm = VM::new();

    println!("Disassembling bytecode...\n");
    println!("{}", vm.disassemble(&chunk, "main"));

    println!("Interpreting bytecode...\n");
    let result = vm.interprete(chunk);
    if let Err(error) = result {
        eprintln!("{:?}", error);
    }
}
