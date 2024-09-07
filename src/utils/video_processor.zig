const std = @import("std");

pub const VideoProcessor = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) VideoProcessor {
        return .{ .allocator = allocator };
    }

    pub fn getVideoDuration(self: *VideoProcessor, path: [:0]const u8) !f32 {
        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][:0]const u8{
                "ffprobe",
                "-v",
                "error",
                "-show_entries",
                "format=duration",
                "-of",
                "default=noprint_wrappers=1:nokey=1",
                path,
            },
        });

        if (result.stderr.len > 0) {
            std.debug.print("FFprobe error: {s}\n", .{result.stderr});
            return error.FFprobeError;
        }

        const trimmed = std.mem.trim(u8, result.stdout, &std.ascii.whitespace);
        return std.fmt.parseFloat(f32, trimmed) catch |err| {
            std.debug.print("Error parsing duration: {s}\n", .{trimmed});
            return err;
        };
    }

    pub fn concatenateVideos(self: *VideoProcessor, input_files: []const [:0]const u8, output_file: [:0]const u8) !void {
        var args = std.ArrayList([:0]const u8).init(self.allocator);
        defer args.deinit();

        try args.appendSlice(&[_][:0]const u8{ "ffmpeg", "-y" });

        for (input_files) |file| {
            try args.appendSlice(&[_][:0]const u8{ "-i", file });
        }

        // Create a dynamic filter complex string
        var filter_complex = std.ArrayList(u8).init(self.allocator);
        defer filter_complex.deinit();

        // Video concatenation
        for (0..input_files.len) |i| {
            try std.fmt.format(filter_complex.writer(), "[{d}:v]", .{i});
        }
        try std.fmt.format(filter_complex.writer(), "concat=n={d}:v=1[outv];", .{input_files.len});

        // Audio concatenation (if available)
        var has_audio = false;
        for (0..input_files.len) |i| {
            if (try self.hasAudioStream(input_files[i])) {
                try std.fmt.format(filter_complex.writer(), "[{d}:a]", .{i});
                has_audio = true;
            }
        }
        if (has_audio) {
            try std.fmt.format(filter_complex.writer(), "concat=n={d}:v=0:a=1[outa]", .{input_files.len});
        }

        const filter_complex_str = try self.allocator.dupeZ(u8, filter_complex.items);
        defer self.allocator.free(filter_complex_str);

        try args.appendSlice(&[_][:0]const u8{
            "-filter_complex",
            filter_complex_str,
            "-map",
            "[outv]",
        });

        if (has_audio) {
            try args.appendSlice(&[_][:0]const u8{
                "-map",
                "[outa]",
            });
        }

        try args.append(output_file);

        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = args.items,
        });

        if (std.mem.indexOf(u8, result.stderr, "Error") != null) {
            std.debug.print("FFmpeg error: {s}\n", .{result.stderr});
            return error.FFmpegError;
        }

        std.debug.print("Videos concatenated successfully\n", .{});
    }

    pub fn hasAudioStream(self: *VideoProcessor, path: [:0]const u8) !bool {
        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][:0]const u8{
                "ffprobe",
                "-v",
                "error",
                "-select_streams",
                "a",
                "-count_packets",
                "-show_entries",
                "stream=nb_read_packets",
                "-of",
                "csv=p=0",
                path,
            },
        });

        if (result.stderr.len > 0) {
            std.debug.print("FFprobe error: {s}\n", .{result.stderr});
            return error.FFprobeError;
        }

        const trimmed = std.mem.trim(u8, result.stdout, &std.ascii.whitespace);
        const packet_count = std.fmt.parseInt(u32, trimmed, 10) catch |err| {
            std.debug.print("Error {} parsing packet count: {s}\n", .{ err, trimmed });
            return false;
        };
        return packet_count > 0;
    }
    pub fn convertTo916(self: *VideoProcessor, input_file: [:0]const u8, output_file: [:0]const u8) !void {
        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][:0]const u8{
                "ffmpeg",
                "-i",
                input_file,
                "-vf",
                "crop=ih*9/16:ih,scale=1080:1920",
                "-c:a",
                "copy",
                output_file,
            },
        });

        // Check for actual errors in the stderr output
        if (std.mem.indexOf(u8, result.stderr, "Error") != null) {
            std.debug.print("FFmpeg error: {s}\n", .{result.stderr});
            return error.FFmpegError;
        }

        std.debug.print("Video converted successfully\n", .{});
    }
};
