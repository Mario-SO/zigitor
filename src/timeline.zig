const std = @import("std");

pub const VideoClip = struct {
    path: [:0]const u8,
    duration: f32,
    has_audio: bool,
};

pub const Timeline = struct {
    clips: std.ArrayList(VideoClip),
    total_duration: f32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Timeline {
        return Timeline{
            .clips = std.ArrayList(VideoClip).init(allocator),
            .total_duration = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Timeline) void {
        for (self.clips.items) |clip| {
            self.allocator.free(clip.path);
        }
        self.clips.deinit();
    }

    pub fn addClip(self: *Timeline, path: [:0]const u8, duration: f32, has_audio: bool) !void {
        const clip = VideoClip{ .path = path, .duration = duration, .has_audio = has_audio };
        try self.clips.append(clip);
        self.total_duration += duration;
    }
};
