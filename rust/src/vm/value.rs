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

#[repr(u8)]
pub enum Type {
    Integer = 0,
    String,
}
