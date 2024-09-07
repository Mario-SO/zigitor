const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const export_manager = @import("../components/export_manager.zig");
const layout = @import("layout.zig");

pub fn render(em: *export_manager.ExportManager) void {
    const x = layout.SCREEN_WIDTH - layout.BUTTON_WIDTH - layout.BUTTON_PADDING;
    const y = layout.SCREEN_HEIGHT - layout.TIMELINE_HEIGHT - (layout.BUTTON_HEIGHT + layout.BUTTON_PADDING) * 3;

    if (rg.guiButton(.{ .x = @floatFromInt(x), .y = @floatFromInt(y), .width = layout.BUTTON_WIDTH, .height = layout.BUTTON_HEIGHT }, "Export") != 0) {
        em.exportVideo() catch |err| {
            std.debug.print("Error exporting video: {}\n", .{err});
        };
    }

    if (rg.guiButton(.{ .x = @floatFromInt(x), .y = @floatFromInt(y + layout.BUTTON_HEIGHT + layout.BUTTON_PADDING), .width = layout.BUTTON_WIDTH, .height = layout.BUTTON_HEIGHT }, "Convert to 9:16") != 0) {
        em.convertTo916() catch |err| {
            std.debug.print("Error converting video to 9:16: {}\n", .{err});
        };
    }
}
