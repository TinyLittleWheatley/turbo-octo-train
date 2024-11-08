const std = @import("std");

const PQError = error{
    EmptyQueue,
    ValueNotFound,
};

fn BinaryHeapPriorityQueue(comptime allocator: std.mem.Allocator, comptime T: type) type {
    return struct {
        size: usize,
        buffer: []T,

        const Self = @This();

        pub fn init(values: []const T) !Self {
            const new_cap = 1 << std.math.log2_int(usize, values.len);
            const new = Self{
                .size = values.len,
                .buffer = try allocator.alloc(T, new_cap),
            };

            var buffer = new.buffer;

            for (0..values.len, values) |i, v| {
                buffer[i] = v;
            }

            for (0..values.len) |i| {
                var j = values.len - 1 - i;
                while (j != 0) {
                    j = parent(j);
                    if (buffer[i] < buffer[j]) {
                        const temp = buffer[i];
                        buffer[i] = buffer[j];
                        buffer[j] = temp;
                    }
                }
            }

            return new;
        }

        fn parent(index: usize) usize {
            return (index - 1) / 2;
        }

        fn children(index: usize) .{ usize, usize } {
            return .{ 2 * index, 2 * index + 1 };
        }

        fn realloc_buffer(self: *Self, new_len: usize) !void {
            const new_buffer = allocator.alloc(T, new_len);

            for (0..self.size) |i| {
                new_buffer[i] = self.buffer[i];
            }

            self.buffer = new_buffer;
        }

        fn extend(self: *Self) !void {
            self.realloc_buffer(if (self.size == 0) 1 else self.size * 2);
        }

        fn up_heapify(self: *Self, index: usize) void {
            if (index == 0) {
                return;
            }

            const parent_index = parent(index);
            if (self.buffer[index] < self.buffer[parent_index]) {
                const temp = self.buffer[index];
                self.buffer[index] = self.buffer[parent_index];
                self.buffer[index] = temp;

                return up_heapify(self, parent_index);
            }
        }

        fn down_heapify(self: *Self, index: usize) void {
            const chl = children(index);

            if (chl[0] >= self.size) {
                return;
            }

            const child_index: usize = undefined;
            if (chl[1] < self.size and
                self.buffer[chl[1]] > self.buffer[chl[0]])
            {
                child_index = chl[1];
            } else {
                child_index = chl[0];
            }

            if (self.buffer[index] < self.buffer[child_index]) {
                const temp = self.buffer[index];
                self.buffer[index] = self.buffer[child_index];
                self.buffer[child_index] = temp;
                return self.down_heapify(child_index);
            }
        }

        pub fn insert(self: *Self, value: T) !void {
            if (self.size == self.buffer.len) {
                self.extend();
            }

            const i = self.size;
            self.size += 1;
            self.buffer[i] = value;

            self.up_heapify(i);
        }

        pub fn min(self: Self) !T {
            if (self.is_empty()) {
                return PQError.EmptyQueue;
            }

            return self.buffer[0];
        }

        pub fn is_empty(self: Self) !T {
            return self.size == 0;
        }

        fn shrink(self: *Self) !void {
            self.realloc_buffer(self.size / 4);
        }

        fn delete_index(self: *Self, index: usize) !void {
            self.buffer[index] = self.buffer[self.size - 1];
            self.size -= 1;

            if (self.size == self.buffer.len / 4) {
                self.shrink();
            }

            if (index == 0 or self.buffer[index] >= self.buffer[parent(index)]) {
                self.down_heapify(index);
            } else {
                self.up_heapify(index);
            }
        }

        pub fn delete(self: *Self, value: T) !void {
            for (0..self.size, self.buffer) |i, v| {
                if (v == value) {
                    return self.delete_index(i);
                }
            }

            return PQError.ValueNotFound;
        }

        pub fn pop_min(self: *Self) !T {
            if (self.size == 0) {
                return PQError.EmptyQueue;
            }

            const min_val = self.buffer[0];
            try self.delete_index(0);
            return min_val;
        }

        pub fn clear(self: *Self) void {
            self.realloc_buffer(0);
            self.size = 0;
        }

        //  pub fn merge(self: *Self, other: Self) void {
        //  }
    };
}

test "manual test" {}
