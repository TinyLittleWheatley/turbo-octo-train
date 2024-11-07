const std = @import("std");

const PQError = error{
    EmptyQueue,
    ValueNotFound,
};

fn LinkedListPriorityQueue(comptime allocator: std.mem.Allocator, comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Node = struct {
            value: T,
            next: ?*Node,
        };

        first: ?*Node,

        pub fn init(values: []const T) !Self {
            var new = Self{
                .first = null,
            };

            for (values) |value| {
                try new.insert(value);
            }

            return new;
        }

        pub fn insert(self: *Self, value: T) !void {
            const node = try allocator.create(Node);
            node.* = Node{ .value = value, .next = self.first };
            self.first = node;
        }

        pub fn min(self: *const Self) !T {
            var n = if (self.first) |first| first else return PQError.EmptyQueue;
            var min_val = n.value;
            while (n.next) |next| {
                n = next;
                if (n.value < min_val) {
                    min_val = n.value;
                }
            }

            return min_val;
        }

        pub fn delete(self: *Self, value: T) !void {
            var n = &self.first;
            while (n.*) |node| {
                if (node.value == value) {
                    n.* = node.next;
                    allocator.destroy(node);
                    return;
                }
                n = &node.next;
            }

            return PQError.ValueNotFound;
        }

        pub fn pop_min(self: *Self) !T {
            const min_val = try self.min();
            try self.delete(min_val);
            return min_val;
        }

        pub fn clear(self: *Self) void {
            var n = self.first;
            while (n) |node| {
                n = node.next;
                allocator.destroy(node);
            }
        }

        pub fn merge(self: *Self, other: Self) void {
            var n = &self.first;
            while (n.*) |node| {
                n = &node.next;
            }

            n.* = other.first;
        }

        pub fn is_empty(self: Self) bool {
            return bool(self.first);
        }
    };
}

test "manual test" {
    const allocator = std.testing.allocator;

    const start: [2]u32 = [_]u32{ 4, 5 };
    var ll = try LinkedListPriorityQueue(allocator, u32).init(&start);
    defer ll.clear();

    try std.testing.expectEqual(4, ll.min());

    const ostart: [1]u32 = [_]u32{3};
    const oll = try LinkedListPriorityQueue(allocator, u32).init(&ostart);
    ll.merge(oll);
    try std.testing.expectEqual(3, ll.min());

    try ll.insert(2);
    try std.testing.expectEqual(2, ll.min());
    try ll.insert(3);
    try ll.insert(0);
    try ll.delete(0);
    try std.testing.expectEqual(2, ll.min());
    try ll.insert(1);
    try std.testing.expectEqual(1, ll.pop_min());
}
