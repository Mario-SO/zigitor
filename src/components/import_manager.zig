const std = @import("std");
const timeline = @import("timeline.zig");
const VideoProcessor = @import("../utils/video_processor.zig").VideoProcessor;

pub const ImportManager = struct {
    imported_videos: std.ArrayList([:0]const u8),
    timeline: *timeline.Timeline,
    video_processor: VideoProcessor,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, tl: *timeline.Timeline) !ImportManager {
        return ImportManager{
            .imported_videos = std.ArrayList([:0]const u8).init(allocator),
            .timeline = tl,
            .video_processor = VideoProcessor.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ImportManager) void {
        for (self.imported_videos.items) |path| {
            self.allocator.free(path);
        }
        self.imported_videos.deinit();
    }

    pub fn importVideo(self: *ImportManager, path: []const u8) !void {
        const duped_path = try self.allocator.dupeZ(u8, path);
        try self.imported_videos.append(duped_path);
    }

    pub fn addToTimeline(self: *ImportManager, path: [:0]const u8) !void {
        const duration = self.video_processor.getVideoDuration(path) catch |err| {
            std.debug.print("Error getting video duration: {}\n", .{err});
            return err;
        };
        const has_audio = self.video_processor.hasAudioStream(path) catch |err| {
            std.debug.print("Error checking for audio stream: {}\n", .{err});
            return err;
        };
        try self.timeline.addClip(path, duration, has_audio);
    }
};
