#[derive(Clone, Copy, Debug)]
pub enum Type {
    Integer = 1,
}

pub struct Value {
    pub type_: Type,
    pub data: ValueData,
}

impl std::fmt::Debug for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.type_ {
            Type::Integer => f
                .debug_struct("Value")
                .field("type", &self.type_)
                .field("data", unsafe { &self.data.integer })
                .finish(),
        }
    }
}

pub union ValueData {
    pub integer: u64,
}
