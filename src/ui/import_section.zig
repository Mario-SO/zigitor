const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const import_manager = @import("../components/import_manager.zig");
const layout = @import("layout.zig");

pub fn render(im: *import_manager.ImportManager) void {
    const x = 0;
    const y = 0;
    rl.drawRectangle(@intCast(x), @intCast(y), layout.IMPORT_SECTION_WIDTH, layout.SCREEN_HEIGHT - layout.TIMELINE_HEIGHT, rl.Color.gray);
    rl.drawText("Import Videos", x + 10, y + 10, 20, rl.Color.white);

    if (rg.guiButton(.{
        .x = @floatFromInt(x + 10),
        .y = @floatFromInt(y + 40),
        .width = layout.IMPORT_SECTION_WIDTH - 20,
        .height = layout.IMPORT_BUTTON_HEIGHT,
    }, "Import Video") != 0) {
        importVideo(im) catch |err| {
            std.debug.print("Error importing video: {}\n", .{err});
        };
    }

    for (im.imported_videos.items, 0..) |video, i| {
        const button_y = @as(i32, @intCast(y + 80 + i * (layout.BUTTON_HEIGHT + layout.BUTTON_PADDING)));
        if (rg.guiButton(.{
            .x = @floatFromInt(x + 10),
            .y = @floatFromInt(button_y),
            .width = layout.IMPORT_SECTION_WIDTH - 20,
            .height = layout.BUTTON_HEIGHT,
        }, video) != 0) {
            im.addToTimeline(video) catch |err| {
                std.debug.print("Error adding video to timeline: {s} - {}\n", .{ video, err });
            };
        }
    }
}

fn importVideo(im: *import_manager.ImportManager) !void {
    std.debug.print("Enter the path to the video file: ", .{});
    var buffer: [1024]u8 = undefined;
    const stdin = std.io.getStdIn().reader();
    if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |user_input| {
        const path = std.mem.trim(u8, user_input, &std.ascii.whitespace);
        try im.importVideo(path);
        std.debug.print("Video imported: {s}\n", .{path});
    } else {
        std.debug.print("No input provided.\n", .{});
    }
}
