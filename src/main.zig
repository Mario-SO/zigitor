const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const timeline = @import("timeline.zig");
const import_manager = @import("import_manager.zig");
const export_manager = @import("export_manager.zig");

// Constants for UI layout
const SCREEN_WIDTH = 1920;
const SCREEN_HEIGHT = 1080;
const TIMELINE_HEIGHT = 150;
const PREVIEW_WIDTH = 960;
const PREVIEW_HEIGHT = 540;
const IMPORT_SECTION_WIDTH = 300;
const BUTTON_WIDTH = 200;
const BUTTON_HEIGHT = 40;
const BUTTON_PADDING = 10;
const IMPORT_BUTTON_HEIGHT = 30;

// Colors
const BG_COLOR = rl.Color.white;
const TIMELINE_COLOR = rl.Color.yellow;

// Structures
const VideoClip = struct {
    path: []const u8,
    duration: f32,
};

const Timeline = struct {
    clips: std.ArrayList(VideoClip),
    total_duration: f32,

    fn init(allocator: std.mem.Allocator) Timeline {
        return Timeline{
            .clips = std.ArrayList(VideoClip).init(allocator),
            .total_duration = 0,
        };
    }

    fn deinit(self: *Timeline) void {
        self.clips.deinit();
    }
};

// Function declarations
fn renderTimeline(tl: *const timeline.Timeline) void {
    rl.drawRectangle(0, SCREEN_HEIGHT - TIMELINE_HEIGHT, SCREEN_WIDTH, TIMELINE_HEIGHT, TIMELINE_COLOR);

    var x: i32 = 0;
    for (tl.clips.items) |clip| {
        const width = (clip.duration / tl.total_duration) * @as(f32, SCREEN_WIDTH);
        rl.drawRectangle(x, SCREEN_HEIGHT - TIMELINE_HEIGHT, @intFromFloat(width), TIMELINE_HEIGHT, rl.Color.blue);
        rl.drawText(clip.path, x + 5, SCREEN_HEIGHT - TIMELINE_HEIGHT + 5, 10, rl.Color.black);
        x += @intFromFloat(width);
    }
}

fn renderImportSection(im: *import_manager.ImportManager) void {
    const x = 0;
    const y = 0;
    rl.drawRectangle(@intCast(x), @intCast(y), IMPORT_SECTION_WIDTH, SCREEN_HEIGHT - TIMELINE_HEIGHT, rl.Color.gray);
    rl.drawText("Import Videos", x + 10, y + 10, 20, rl.Color.white);

    // Add import button
    if (rg.guiButton(.{
        .x = @floatFromInt(x + 10),
        .y = @floatFromInt(y + 40),
        .width = IMPORT_SECTION_WIDTH - 20,
        .height = IMPORT_BUTTON_HEIGHT,
    }, "Import Video") != 0) {
        importVideo(im) catch |err| {
            std.debug.print("Error importing video: {}\n", .{err});
        };
    }

    // Render imported videos list
    for (im.imported_videos.items, 0..) |video, i| {
        const button_y = @as(i32, @intCast(y + 80 + i * (BUTTON_HEIGHT + BUTTON_PADDING)));
        if (rg.guiButton(.{
            .x = @floatFromInt(x + 10),
            .y = @floatFromInt(button_y),
            .width = IMPORT_SECTION_WIDTH - 20,
            .height = BUTTON_HEIGHT,
        }, video) != 0) {
            im.addToTimeline(video) catch |err| {
                std.debug.print("Error adding video to timeline: {s} - {}\n", .{ video, err });
            };
        }
    }
}

// Add this new function to handle video import
fn importVideo(im: *import_manager.ImportManager) !void {
    // In a real application, you'd use a file dialog here.
    // For this example, we'll use a simple command-line input.
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

fn renderPreview() void {
    const x = IMPORT_SECTION_WIDTH + (SCREEN_WIDTH - IMPORT_SECTION_WIDTH - PREVIEW_WIDTH) / 2;
    const y = (SCREEN_HEIGHT - TIMELINE_HEIGHT - PREVIEW_HEIGHT) / 2;
    rl.drawRectangle(@intCast(x), @intCast(y), PREVIEW_WIDTH, PREVIEW_HEIGHT, rl.Color.gray);
    rl.drawText("Preview", x + 10, y + 10, 20, rl.Color.white);
}

fn renderControlButtons(em: *export_manager.ExportManager) void {
    const x = SCREEN_WIDTH - BUTTON_WIDTH - BUTTON_PADDING;
    const y = SCREEN_HEIGHT - TIMELINE_HEIGHT - (BUTTON_HEIGHT + BUTTON_PADDING) * 3;

    if (rg.guiButton(.{ .x = @floatFromInt(x), .y = @floatFromInt(y), .width = BUTTON_WIDTH, .height = BUTTON_HEIGHT }, "Export") != 0) {
        em.exportVideo() catch |err| {
            std.debug.print("Error exporting video: {}\n", .{err});
        };
    }

    if (rg.guiButton(.{ .x = @floatFromInt(x), .y = @floatFromInt(y + BUTTON_HEIGHT + BUTTON_PADDING), .width = BUTTON_WIDTH, .height = BUTTON_HEIGHT }, "Convert to 9:16") != 0) {
        em.convertTo916() catch |err| {
            std.debug.print("Error converting video to 9:16: {}\n", .{err});
        };
    }
}

pub fn main() !void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "⚡ Zigitor - Video Editor");
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

        rl.clearBackground(rl.Color.white);

        renderTimeline(&tl);
        renderPreview();
        renderImportSection(&im);
        renderControlButtons(&em);

        rl.drawFPS(10, 10);
    }
}
