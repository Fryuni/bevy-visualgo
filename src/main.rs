use bevy::diagnostic::FrameCount;
use bevy::{app::AppExit, prelude::*};
use bevy_ratatui::event::KeyEvent;
use bevy_ratatui::{RatatuiContext, RatatuiPlugins};
use ratatui::crossterm::event::KeyCode;
use ratatui::prelude::*;

fn main() {
    App::new()
        .add_plugins((
            MinimalPlugins.set(bevy::app::ScheduleRunnerPlugin::run_loop(
                std::time::Duration::from_secs_f32(1. / 60.),
            )),
            RatatuiPlugins::default(),
        ))
        .add_systems(Main, input_system)
        .add_systems(Update, draw_system)
        .run();
}

fn draw_system(mut context: ResMut<RatatuiContext>, frames: Res<FrameCount>) -> Result {
    context.draw(|frame| {
        frame.render_widget(
            Text::raw(format!("Frame count: {}", frames.0)),
            frame.area(),
        );
    })?;

    Ok(())
}

fn input_system(mut events: EventReader<KeyEvent>, mut exit: EventWriter<AppExit>) {
    for event in events.read() {
        if let KeyCode::Char('q') = event.code {
            exit.write_default();
        }
    }
}
