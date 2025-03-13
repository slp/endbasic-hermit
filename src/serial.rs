use std::arch::asm;
use std::io;

use async_trait::async_trait;
use endbasic_std::console::graphics::InputOps;
use endbasic_std::console::{
    get_env_var_as_u16, remove_control_chars, CharsXY, ClearType, Console, Key,
};

/// Default number of columns for when `COLUMNS` is not set.
const DEFAULT_COLUMNS: u16 = 80;

/// Default number of lines for when `LINES` is not set.
const DEFAULT_LINES: u16 = 24;

/// Converts a line of text into a collection of keys.
fn char_to_key(ch: u8) -> Key {
    if ch == b'\x1b' {
        Key::Escape
    } else if ch == b'\n' || ch == b'\r' {
        Key::NewLine
    } else if ch == b'\x7f' {
        Key::Backspace
    } else if ch == 1 {
        Key::Home
    } else if ch == 5 {
        Key::End
    } else if ch == 9 {
        Key::Tab
    } else if !ch.is_ascii_control() {
        Key::Char(ch as char)
    } else {
        Key::Unknown(ch.to_string())
    }
}

/// Implementation of the EndBASIC console with minimal functionality.
#[derive(Default)]
pub struct SerialConsole {}

impl SerialConsole {
    pub fn new() -> Self {
        Self {}
    }

    fn read_char(&mut self) -> Option<Key> {
        let dr = (0x8000_1000u64) as *mut u16;
        let fr = (0x8000_1000u64 + 0x18) as *mut u32;

        unsafe {
            if (fr.read_volatile() & 0x10) != 0 {
                return None;
            }
            let byte = dr.read_volatile();

            if byte == 27 && self.wait_data(1000) {
                Some(self.read_sequence())
            } else {
                Some(char_to_key(byte as u8))
            }
        }
    }

    fn read_sequence(&mut self) -> Key {
        let dr = (0x8000_1000u64) as *mut u16;

        let byte = unsafe { dr.read_volatile() };

        if byte != 91 {
            println!("byte={}", byte);
            return Key::Unknown("Invalid sequence".to_string());
        }

        if !self.wait_data(1000) {
            println!("!wait_data");
            return Key::Unknown("Invalid sequence".to_string());
        }

        let byte = unsafe { dr.read_volatile() };

        if byte == 53 || byte == 54 {
            // Consume sequence terminator.
            if self.wait_data(1000) {
                unsafe { dr.read_volatile() };
            }
        }

        match byte {
            49 => Key::Home,
            52 => Key::End,
            65 => Key::ArrowUp,
            66 => Key::ArrowDown,
            67 => Key::ArrowRight,
            68 => Key::ArrowLeft,
            53 => Key::PageUp,
            54 => Key::PageDown,
            70 => Key::End,
            72 => Key::Home,
            _ => {
                println!("unknown byte={}", byte);
                Key::Unknown("Unknown sequence".to_string())
            }
        }
    }

    fn wait_data(&mut self, cycles: u64) -> bool {
        let fr = (0x8000_1000u64 + 0x18) as *mut u32;

        for _ in 0..cycles {
            unsafe {
                if (fr.read_volatile() & 0x10) == 0 {
                    return true;
                }
                asm!("nop");
            }
        }
        false
    }

    fn read_char_sync(&mut self) -> Key {
        let dr = (0x8000_1000u64) as *mut u16;
        let fr = (0x8000_1000u64 + 0x18) as *mut u32;

        unsafe {
            while (fr.read_volatile() & 0x10) != 0 {
                asm!("nop");
            }
            let byte = dr.read_volatile();
            println!("read: {:?}", byte);

            if byte == 27 && self.wait_data(1000) {
                println!("read_sequence");
                self.read_sequence()
            } else {
                char_to_key(byte as u8)
            }
        }
    }

    fn write_char(&mut self, byte: u8) {
        let dr = (0x8000_1000u64) as *mut u8;
        let fr = (0x8000_1000u64 + 0x18) as *mut u32;

        unsafe {
            while (fr.read_volatile() & 0x20) != 0 {
                asm!("nop");
            }
            dr.write_volatile(byte);
        }
    }

    pub fn write_bytes(&mut self, bytes: &[u8]) {
        for byte in bytes.iter().copied() {
            //println!("byte={:x}", byte);
            if byte == b'\n' {
                self.write_char(b'\r');
            }
            self.write_char(byte);
        }
    }
}

#[async_trait(?Send)]
impl InputOps for SerialConsole {
    async fn poll_key(&mut self) -> io::Result<Option<Key>> {
        Ok(self.read_char())
    }

    async fn read_key(&mut self) -> io::Result<Key> {
        Ok(self.read_char_sync())
    }
}

#[async_trait(?Send)]
impl Console for SerialConsole {
    fn clear(&mut self, _how: ClearType) -> io::Result<()> {
        Ok(())
    }

    fn color(&self) -> (Option<u8>, Option<u8>) {
        (None, None)
    }

    fn set_color(&mut self, _fg: Option<u8>, _bg: Option<u8>) -> io::Result<()> {
        Ok(())
    }

    fn enter_alt(&mut self) -> io::Result<()> {
        Ok(())
    }

    fn hide_cursor(&mut self) -> io::Result<()> {
        Ok(())
    }

    fn is_interactive(&self) -> bool {
        true
    }

    fn leave_alt(&mut self) -> io::Result<()> {
        Ok(())
    }

    #[cfg_attr(not(debug_assertions), allow(unused))]
    fn locate(&mut self, pos: CharsXY) -> io::Result<()> {
        #[cfg(debug_assertions)]
        {
            let size = self.size_chars()?;
            assert!(pos.x < size.x);
            assert!(pos.y < size.y);
        }
        Ok(())
    }

    fn move_within_line(&mut self, _off: i16) -> io::Result<()> {
        Ok(())
    }

    fn print(&mut self, text: &str) -> io::Result<()> {
        let text = remove_control_chars(text);

        self.write_bytes(text.as_bytes());
        self.write_char(b'\n');
        Ok(())
    }

    async fn poll_key(&mut self) -> io::Result<Option<Key>> {
        Ok(self.read_char())
    }

    async fn read_key(&mut self) -> io::Result<Key> {
        Ok(self.read_char_sync())
    }

    fn show_cursor(&mut self) -> io::Result<()> {
        Ok(())
    }

    fn size_chars(&self) -> io::Result<CharsXY> {
        let lines = get_env_var_as_u16("LINES").unwrap_or(DEFAULT_LINES);
        let columns = get_env_var_as_u16("COLUMNS").unwrap_or(DEFAULT_COLUMNS);
        Ok(CharsXY::new(columns, lines))
    }

    fn write(&mut self, text: &str) -> io::Result<()> {
        let text = remove_control_chars(text);

        self.write_bytes(text.as_bytes());
        Ok(())
    }

    fn sync_now(&mut self) -> io::Result<()> {
        Ok(())
    }

    fn set_sync(&mut self, _enabled: bool) -> io::Result<bool> {
        Ok(true)
    }
}
