#[derive(Clone, Copy, Debug)]
pub enum Type {
    Integer = 0,
    String,
}

pub struct Value {
    pub type_: Type,
    pub data: ValueData,
}

impl std::fmt::Debug for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Value")
            .field("type", &self.type_)
            .field(
                "data",
                match self.type_ {
                    Type::Integer => unsafe { &self.data.integer },
                    Type::String => unsafe { &self.data.string },
                },
            )
            .finish()
    }
}

impl Value {
    pub fn integer(integer: u64) -> Value {
        Value {
            type_: Type::Integer,
            data: ValueData { integer },
        }
    }

    pub fn string(string: String) -> Value {
        Value {
            type_: Type::String,
            data: ValueData {
                string: std::mem::ManuallyDrop::new(string),
            },
        }
    }
}

pub union ValueData {
    pub integer: u64,
    pub string: std::mem::ManuallyDrop<String>,
}
