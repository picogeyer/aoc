const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const fmt = std.fmt;

const ParseError = error{
    GameDivNotFound,
    InvalidColor,
};

fn read_line(reader: anytype, buffer: []u8) !?[]const u8 {
    return try reader.readUntilDelimiterOrEof(buffer, '\n');
}

/// Takes a string with sub games seperated by ;
/// Checks that each subgame does not violate the restrictions
/// and returns true if so else false
fn is_game_valid(game_str: []const u8) !bool {
    const max_red: u32 = 12;
    const max_green: u32 = 13;
    const max_blue: u32 = 14;
    var game_itr = std.mem.splitScalar(u8, game_str, ';');
    var game_valid = true;
    while (game_itr.next()) |game| {
        std.debug.print("Next sub game is: {s}\n", .{game});
        var red_cubes: u32 = 0;
        var blue_cubes: u32 = 0;
        var green_cubes: u32 = 0;
        var dice_itr = std.mem.splitScalar(u8, game, ',');
        while (dice_itr.next()) |dice| {
            const dice_trim = std.mem.trim(u8, dice, " ");
            var dice_str_itr = std.mem.splitScalar(u8, dice_trim, ' ');
            const num_dice_str = dice_str_itr.next().?;
            const color = dice_str_itr.next().?;
            const num_dice = try fmt.parseInt(u32, num_dice_str, 10);
            if (mem.eql(u8, color, "red")) {
                red_cubes = num_dice;
            } else if (mem.eql(u8, color, "green")) {
                green_cubes = num_dice;
            } else if (mem.eql(u8, color, "blue")) {
                blue_cubes = num_dice;
            } else {
                return ParseError.InvalidColor;
            }
        }

        // Does this game violate the restrictions?
        if (red_cubes > max_red or green_cubes > max_green or blue_cubes > max_blue) {
            game_valid = false;
            break;
        }
    }
    return game_valid;
}

pub fn main() !void {
    const in_file = try fs.cwd().openFile("input.txt", .{});
    defer in_file.close();
    var buff: [256]u8 = undefined;
    var sum_of_games: u32 = 0;
    while (try read_line(in_file.reader(), &buff)) |line| {
        std.debug.print("Next line is {s}\n", .{line});
        const game_div = mem.indexOf(u8, line, ":");
        if (game_div == null) {
            return ParseError.GameDivNotFound;
        }
        const game_str = line[0..game_div.?];
        const rem_str = line[game_div.? + 1 ..];
        const game_str_prefix = game_str["Game ".len..];
        const game_num = try fmt.parseInt(u32, game_str_prefix, 10);
        const game_valid = try is_game_valid(rem_str);
        if (!game_valid) {
            std.debug.print("Game number {d} is not valid\n", .{game_num});
        }
        if (game_valid) {
            sum_of_games += game_num;
            std.debug.print("Adding valid game number {d}. Total is now: {d}\n", .{ game_num, sum_of_games });
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("The final sum of games is {d}\n", .{sum_of_games});
}
