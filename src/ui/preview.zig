const rl = @import("raylib");
const layout = @import("layout.zig");

pub fn render() void {
    const x = layout.IMPORT_SECTION_WIDTH + (layout.SCREEN_WIDTH - layout.IMPORT_SECTION_WIDTH - layout.PREVIEW_WIDTH) / 2;
    const y = (layout.SCREEN_HEIGHT - layout.TIMELINE_HEIGHT - layout.PREVIEW_HEIGHT) / 2;
    rl.drawRectangle(@intCast(x), @intCast(y), layout.PREVIEW_WIDTH, layout.PREVIEW_HEIGHT, rl.Color.gray);
    rl.drawText("Preview", x + 10, y + 10, 20, rl.Color.white);
}
