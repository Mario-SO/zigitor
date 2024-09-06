const std = @import("std");
const timeline = @import("timeline.zig");
const VideoProcessor = @import("video_processor.zig").VideoProcessor;

pub const ExportManager = struct {
    timeline: *timeline.Timeline,
    video_processor: VideoProcessor,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, tl: *timeline.Timeline) !ExportManager {
        return ExportManager{
            .timeline = tl,
            .video_processor = VideoProcessor.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ExportManager) void {
        _ = self;
    }

    pub fn exportVideo(self: *ExportManager) !void {
        var input_files = std.ArrayList([:0]const u8).init(self.allocator);
        defer input_files.deinit();

        for (self.timeline.clips.items) |clip| {
            try input_files.append(clip.path);
        }

        try self.video_processor.concatenateVideos(input_files.items, "processed/output.mp4");
    }

    pub fn convertTo916(self: *ExportManager) !void {
        if (self.timeline.clips.items.len == 0) {
            return error.NoClipsInTimeline;
        }

        try self.video_processor.convertTo916(self.timeline.clips.items[0].path, "output_916.mp4");
    }
};
