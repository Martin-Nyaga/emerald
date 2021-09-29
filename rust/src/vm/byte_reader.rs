use std::convert::TryInto;

pub fn read_u64(bytes: &[u8]) -> Option<u64> {
    Some(u64::from_be_bytes(bytes[0..8].try_into().ok()?))
}

pub fn read_u32(bytes: &[u8]) -> Option<u32> {
    Some(u32::from_be_bytes(bytes[0..4].try_into().ok()?))
}

pub fn read_u16(bytes: &[u8]) -> Option<u16> {
    Some(u16::from_be_bytes(bytes[0..2].try_into().ok()?))
}
