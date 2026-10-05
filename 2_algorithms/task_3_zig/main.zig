const std = @import("std");

// Input format: one line or text containing brackets and any other characters.
// Characters other than (), [] and {} are ignored.
// Compatible with Zig 0.13.x.
pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const allocator = general_purpose_allocator.allocator();

    const input = try std.io.getStdIn().reader().readAllAlloc(allocator, 1024 * 1024);
    defer allocator.free(input);

    const result = try isValidBracketSequence(input, allocator);
    if (result) {
        try std.io.getStdOut().writer().writeAll("YES\n");
    } else {
        try std.io.getStdOut().writer().writeAll("NO\n");
    }
}

fn isValidBracketSequence(input: []const u8, allocator: std.mem.Allocator) !bool {
    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    for (input) |character| {
        switch (character) {
            '(', '[', '{' => try stack.append(character),
            ')', ']', '}' => {
                if (stack.items.len == 0) return false;

                const opening = stack.items[stack.items.len - 1];
                _ = stack.pop();
                if (!isMatchingPair(opening, character)) return false;
            },
            else => {},
        }
    }

    return stack.items.len == 0;
}

fn isMatchingPair(opening: u8, closing: u8) bool {
    return (opening == '(' and closing == ')') or
        (opening == '[' and closing == ']') or
        (opening == '{' and closing == '}');
}

test "valid nested sequence" {
    try std.testing.expect(try isValidBracketSequence("{text[(value)]}", std.testing.allocator));
}

test "invalid sequence" {
    try std.testing.expect(!(try isValidBracketSequence("([)]", std.testing.allocator)));
}
