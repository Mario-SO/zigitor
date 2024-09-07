const std = @import("std");
const rl = @import("raylib");
const timeline = @import("../components/timeline.zig");
const layout = @import("layout.zig");

pub fn render(tl: *const timeline.Timeline) void {
    rl.drawRectangle(0, layout.SCREEN_HEIGHT - layout.TIMELINE_HEIGHT, layout.SCREEN_WIDTH, layout.TIMELINE_HEIGHT, layout.TIMELINE_COLOR);

    var x: i32 = 0;
    for (tl.clips.items) |clip| {
        const width = (clip.duration / tl.total_duration) * @as(f32, layout.SCREEN_WIDTH);
        rl.drawRectangle(x, layout.SCREEN_HEIGHT - layout.TIMELINE_HEIGHT, @intFromFloat(width), layout.TIMELINE_HEIGHT, rl.Color.blue);
        rl.drawText(clip.path, x + 5, layout.SCREEN_HEIGHT - layout.TIMELINE_HEIGHT + 5, 10, rl.Color.black);
        x += @intFromFloat(width);
    }
}
