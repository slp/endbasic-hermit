#[cfg(target_os = "hermit")]
use hermit as _;

use std::cell::RefCell;
use std::rc::Rc;

use endbasic_std::console::GraphicsConsole;

mod font16;
mod graphics;
mod serial;

use crate::graphics::Graphics;
use crate::serial::SerialConsole;

static ARKA: &str = include_str!("../res/arka.bas");
static BOUNCE: &str = include_str!("../res/bounce.bas");
static FLAKES: &str = include_str!("../res/flakes.bas");
static LIFE: &str = include_str!("../res/life.bas");
static PAINT: &str = include_str!("../res/paint.bas");
static SNAKE: &str = include_str!("../res/snake.bas");
static WINDEN: &str = include_str!("../res/winden.bas");

#[allow(clippy::await_holding_refcell_ref)]
#[tokio::main]
async fn main() {
    let mut builder = endbasic_std::MachineBuilder::default();
    //let console = Rc::from(RefCell::from(serial::SerialConsole::default()));
    let input = SerialConsole::new();
    let graphics = Graphics::new();
    let console = Rc::from(RefCell::from(
        GraphicsConsole::new(input, graphics).unwrap(),
    ));
    builder = builder.with_console(console);
    let mut builder = builder
        .make_interactive()
        .with_program(Rc::from(RefCell::from(
            endbasic_repl::editor::Editor::default(),
        )));

    let program = builder.get_program();
    let console = builder.get_console();
    {
        let rcstorage = builder.get_storage();
        let mut storage = rcstorage.borrow_mut();
        let _ = storage.put("arka.bas", ARKA).await;
        let _ = storage.put("bounce.bas", BOUNCE).await;
        let _ = storage.put("flakes.bas", FLAKES).await;
        let _ = storage.put("life.bas", LIFE).await;
        let _ = storage.put("paint.bas", PAINT).await;
        let _ = storage.put("snake.bas", SNAKE).await;
        let _ = storage.put("winden.bas", WINDEN).await;
    }
    let mut machine = builder.build().unwrap();

    endbasic_repl::print_welcome(console.clone()).unwrap();
    endbasic_repl::run_repl_loop(&mut machine, console, program)
        .await
        .expect("Error executing REPL loop");
}
