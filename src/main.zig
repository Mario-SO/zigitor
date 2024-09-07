const std = @import("std");
const rl = @import("raylib");
const timeline = @import("components/timeline.zig");
const import_manager = @import("components/import_manager.zig");
const export_manager = @import("components/export_manager.zig");
const timeline_view = @import("ui/timeline_view.zig");
const import_section = @import("ui/import_section.zig");
const preview = @import("ui/preview.zig");
const control_buttons = @import("ui/control_buttons.zig");
const layout = @import("ui/layout.zig");

pub fn main() !void {
    rl.initWindow(layout.SCREEN_WIDTH, layout.SCREEN_HEIGHT, "⚡ Zigitor - Video Editor");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var tl = try timeline.Timeline.init(allocator);
    defer tl.deinit();

    var im = try import_manager.ImportManager.init(allocator, &tl);
    defer im.deinit();

    var em = try export_manager.ExportManager.init(allocator, &tl);
    defer em.deinit();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(layout.BG_COLOR);

        timeline_view.render(&tl);
        preview.render();
        import_section.render(&im);
        control_buttons.render(&em);

        // rl.drawFPS(10, 10);
    }
}
