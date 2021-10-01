pub struct RealFile {
    file_path: String,
    contents: String,
}

impl RealFile {
    pub fn new(file_path: String) -> Self {
        let contents = std::fs::read_to_string(&file_path)
            .map_err(|e| format!("{}", e))
            .unwrap();
        RealFile {
            file_path,
            contents,
        }
    }
}

pub trait File<'a> {
    fn contents(&'a self) -> &'a str;
}

impl<'a> File<'a> for RealFile {
    fn contents(&'a self) -> &'a str {
        &self.contents
    }
}
