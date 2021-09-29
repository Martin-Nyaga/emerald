use crate::vm::byte_reader;

#[derive(Clone, Debug)]
pub enum Value {
    Integer(u64),
    String(String),
}

impl std::fmt::Display for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Value::Integer(x) => write!(f, "{}", x),
            Value::String(x) => write!(f, "\"{}\"", x),
        }
    }
}

impl Value {
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut bytes = vec![];

        match self {
            Value::Integer(x) => {
                bytes.push(Type::Integer as u8);
                bytes.extend(x.to_be_bytes());
            }
            Value::String(x) => {
                bytes.push(Type::String as u8);
                bytes.extend((x.bytes().len() as u64).to_be_bytes());
                bytes.extend(x.bytes().collect::<Vec<u8>>());
            }
        };

        bytes
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<(usize, Value), String> {
        match bytes[0] {
            byte if byte == Type::Integer as u8 => {
                // tag (1 byte), number (8 bytes)
                let number = byte_reader::read_u64(&bytes[1..])
                    .ok_or("couldn't read valid integer".to_owned())?;

                Ok((9, Value::Integer(number)))
            }
            byte if byte == Type::String as u8 => {
                // tag (1 byte), length (8 bytes), data (variable)
                let size = byte_reader::read_u64(&bytes[1..])
                    .ok_or("couldn't read string length".to_owned())?;
                let string = std::str::from_utf8(&bytes[9..(9 + size as usize)])
                    .map_err(|_| "failed to read string")?;
                let value = Value::String(string.to_owned());
                Ok((9 + size as usize, value))
            }
            _ => Err("Unknown literal type".to_owned()),
        }
    }
}

#[repr(u8)]
pub enum Type {
    Integer = 0,
    String,
}
