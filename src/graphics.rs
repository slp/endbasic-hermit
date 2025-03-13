use std::collections::VecDeque;
use std::io;

use bit_vec::BitVec;
use endbasic_std::console::graphics::{RasterInfo, RasterOps};
use endbasic_std::console::{drawing, CharsXY, PixelsXY, SizeInPixels, RGB};

use crate::font16::Font16;

const VCFB: u64 = 0x8020_0000u64;
const VCFB_WIDTH: usize = 1280;
const VCFB_HEIGHT: usize = 720;

pub struct Graphics {
    current_color: u32,
    size_pixels: SizeInPixels,
    font: Font16,
    offscreen: Vec<u32>,
    dirty_pixels: BitVec,
    sync: bool,
}

impl Graphics {
    pub fn new() -> Self {
        let offscreen = vec![0u32; VCFB_WIDTH * VCFB_HEIGHT];
        Self {
            current_color: 0,
            size_pixels: SizeInPixels::new(VCFB_WIDTH as u16, VCFB_HEIGHT as u16),
            font: Font16 {},
            offscreen,
            dirty_pixels: BitVec::from_elem(1280 * 720, false),
            sync: false,
        }
    }

    fn rgb_to_u32(&self, color: RGB) -> u32 {
        let data: u32 = (color.0 as u32) << 16 | (color.1 as u32) << 8 | (color.2 as u32);
        data
    }

    fn update_pixel(&mut self, x: u64, y: u64, color: u32) -> io::Result<()> {
        if x >= self.size_pixels.width as u64 || y >= self.size_pixels.height as u64 {
            //return Err(io::Error::new(io::ErrorKind::InvalidData, "Invalid offset"));
            return Ok(());
        }
        //println!("update_pixel: x={x}, y={y}");
        let offset = y * self.size_pixels.width as u64 + x;
        if self.offscreen[offset as usize] != color {
            self.offscreen[offset as usize] = color;
            self.dirty_pixels.set(offset.try_into().unwrap(), true);
        }

        Ok(())
    }

    fn commit(&mut self) {
        for (index, bit) in self.dirty_pixels.iter().enumerate() {
            if bit {
                unsafe {
                    ((VCFB + (index * 4) as u64) as *mut u32).write_volatile(self.offscreen[index])
                }
            }
        }
        self.dirty_pixels.clear();
    }

    fn fill(&mut self, x1y1: PixelsXY, x2y2: PixelsXY) -> io::Result<()> {
        for y in x1y1.y..(x2y2.y + 1) {
            for x in x1y1.x..(x2y2.x + 1) {
                self.update_pixel(x as u64, y as u64, self.current_color)?;
            }
        }
        Ok(())
    }

    fn clip(&self, xy: PixelsXY, size: SizeInPixels) -> (PixelsXY, SizeInPixels) {
        //println!("clip: xy={:?}, size={:?}", xy, size);
        let (x, w) = if xy.x as u16 + size.width >= self.size_pixels.width {
            let x = self.size_pixels.width - 1;
            //println!("clipping x to {}", x);
            (x, size.width - 1)
        } else {
            (xy.x as u16 + size.width, size.width)
        };
        let (y, h) = if xy.y as u16 + size.height >= self.size_pixels.height {
            let y = self.size_pixels.height - 1;
            //println!("clipping y to {}", y);
            (y, size.height - 1)
        } else {
            (xy.y as u16 + size.height, size.height)
        };
        (
            PixelsXY {
                x: x.try_into().unwrap(),
                y: y.try_into().unwrap(),
            },
            SizeInPixels::new(w, h),
        )
    }
}

impl RasterOps for Graphics {
    type ID = (VecDeque<u32>, SizeInPixels);

    /// Queries information about the backend.
    fn get_info(&self) -> RasterInfo {
        RasterInfo {
            size_pixels: self.size_pixels,
            glyph_size: SizeInPixels::new(16, 16),
            size_chars: CharsXY::new(VCFB_WIDTH as u16 / 16, VCFB_HEIGHT as u16 / 16),
        }
    }

    /// Sets the drawing color for subsequent operations.
    fn set_draw_color(&mut self, color: RGB) {
        self.current_color = self.rgb_to_u32(color);
    }

    /// Clears the whole console with the given color.
    fn clear(&mut self) -> io::Result<()> {
        for y in 0..self.size_pixels.height {
            for x in 0..self.size_pixels.width {
                self.update_pixel(x as u64, y as u64, self.current_color)?;
            }
        }
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Sets whether automatic presentation of the canvas is enabled or not.
    ///
    /// Raster backends might need this when the device they talk to is very slow and they want to
    /// buffer data in main memory first.
    ///
    /// Does *NOT* present the canvas.
    fn set_sync(&mut self, enabled: bool) {
        self.sync = enabled;
    }

    /// Displays any buffered changes to the console.
    ///
    /// Should ignore any sync values that the backend might have cached via `set_sync`.
    fn present_canvas(&mut self) -> io::Result<()> {
        self.commit();
        Ok(())
    }

    /// Reads the raw pixel data for the rectangular region specified by `xy` and `size`.
    fn read_pixels(&mut self, xy: PixelsXY, size: SizeInPixels) -> io::Result<Self::ID> {
        let (x2y2, new_size) = self.clip(xy, size);
        let mut data = VecDeque::new();
        for y in xy.y..(x2y2.y + 1) {
            for x in xy.x..(x2y2.x + 1) {
                let offset = y as u64 * self.size_pixels.width as u64 + x as u64;
                if offset >= 1280 * 720 {
                    println!(
                        "offset={offset} x={x} y={y} xy={}x{}, x2y2={}x{} size={}x{}",
                        xy.x, xy.y, x2y2.x, x2y2.y, size.width, size.height
                    );
                }
                data.push_back(self.offscreen[offset as usize]);
            }
        }
        //println!("read_pixels data_len={}", data.len());
        Ok((data, new_size))
    }

    /// Restores the rectangular region stored in `data` at the `xy` coordinates.
    fn put_pixels(&mut self, xy: PixelsXY, data: &Self::ID) -> io::Result<()> {
        let (x2y2, _size) = self.clip(xy, data.1);
        let mut pos = 0;
        for y in xy.y..(x2y2.y + 1) {
            for x in xy.x..(x2y2.x + 1) {
                if pos >= data.0.len() {
                    println!("too long pos {} data_len={}", pos, data.0.len());
                    println!(
                        "x={x} y={y} xy={}x{}, x2y2={}x{} size={}x{}",
                        xy.x, xy.y, x2y2.x, x2y2.y, data.1.width, data.1.height
                    );
                }
                self.update_pixel(x as u64, y as u64, data.0[pos])?;
                pos += 1;
            }
        }
        Ok(())
    }

    /// Moves the rectangular region specified by `x1y1` and `size` to `x2y2`.  The original region
    /// is erased with the current drawing color.
    fn move_pixels(
        &mut self,
        x1y1: PixelsXY,
        x2y2: PixelsXY,
        size: SizeInPixels,
    ) -> io::Result<()> {
        //println!("move_pixels: {:?}", size);
        let data = self.read_pixels(x1y1, size)?;
        self.draw_rect_filled(x1y1, size)?;
        self.put_pixels(x2y2, &data)?;
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Writes `text` starting at `xy` with the current drawing color.
    fn write_text(&mut self, xy: PixelsXY, text: &str) -> io::Result<()> {
        let mut pos = xy;
        for ch in text.chars() {
            let glyph = self.font.glyph(ch);
            for (j, elements) in glyph.chunks(2).enumerate() {
                let row = (elements[0] as u16) << 8 | elements[1] as u16;
                //println!("element1={:x}, element2={:x}", elements[0], elements[1]);
                //println!("row={:x}", row);
                let mut mask = 0x8000;
                for i in 0..self.font.size().width {
                    let bit = row & mask;
                    if bit != 0 {
                        let x = pos.x + i as i16;
                        if x >= self.size_pixels.width as i16 {
                            continue;
                        }

                        let y = pos.y + j as i16;
                        if y >= self.size_pixels.height as i16 {
                            continue;
                        }

                        let xy = PixelsXY { x, y };
                        self.fill(xy, xy)?;
                    }
                    mask >>= 1;
                }
            }

            pos.x += self.font.size().width as i16;
        }
        //println!("write_text: {text}");
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Draws the outline of a circle at `center` with `radius` using the current drawing color.
    fn draw_circle(&mut self, center: PixelsXY, radius: u16) -> io::Result<()> {
        drawing::draw_circle(self, center, radius)?;
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Draws a filled circle at `center` with `radius` using the current drawing color.
    fn draw_circle_filled(&mut self, center: PixelsXY, radius: u16) -> io::Result<()> {
        drawing::draw_circle_filled(self, center, radius)?;
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Draws a line from `x1y1` to `x2y2` using the current drawing color.
    fn draw_line(&mut self, x1y1: PixelsXY, x2y2: PixelsXY) -> io::Result<()> {
        drawing::draw_line(self, x1y1, x2y2)?;
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Draws a single pixel at `xy` using the current drawing color.
    fn draw_pixel(&mut self, xy: PixelsXY) -> io::Result<()> {
        self.update_pixel(xy.x as u64, xy.y as u64, self.current_color)?;
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Draws the outline of a rectangle from `x1y1` to `x2y2` using the current drawing color.
    fn draw_rect(&mut self, xy: PixelsXY, size: SizeInPixels) -> io::Result<()> {
        drawing::draw_rect(self, xy, size)?;
        if self.sync {
            self.commit();
        }
        Ok(())
    }

    /// Draws a filled rectangle from `x1y1` to `x2y2` using the current drawing color.
    fn draw_rect_filled(&mut self, xy: PixelsXY, size: SizeInPixels) -> io::Result<()> {
        let x2y2 = PixelsXY {
            x: xy.x + size.width as i16,
            y: xy.y + size.height as i16,
        };
        self.fill(xy, x2y2)?;
        if self.sync {
            self.commit();
        }
        Ok(())
    }
}
