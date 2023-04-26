const std = @import("std");
const allocator = std.heap.c_allocator;

pub fn Vec(comptime T: type) type {
    return struct {
        pub const Error = error {
            OutOfMemory,
            OutOfRange,
            VecIsEmpty,
            UnimplementedSortForTypeT,
        };

        data: ?[]T,
        len: usize,

        pub fn new() Vec(T) {
            return Vec(T).init();
        }

        pub fn init() Vec(T) {
            return Vec(T) {
                .data = null,
                .len = 0,
            };
        }

        pub fn populate(self: *Vec(T), value: T, _len: usize) Error!void {
            if (self.data) |data| {
                self.data = allocator.realloc(data, (self.len + _len))
                    catch return Error.OutOfMemory;
            }
            else {
                self.data = allocator.alloc(T, (self.len + _len))
                    catch return Error.OutOfMemory;
            }

            var iter: usize = 0;
            while (iter < _len) : (iter += 1) {
                self.data.?[self.len + iter] = value;
            }

            self.len += _len;
        }

        pub inline fn push(self: *Vec(T), value: T) Error!void {
            self.len += 1;

            if (self.data) |data| {
                self.data = allocator.realloc(data, self.len)
                    catch return Error.OutOfMemory;

                self.data.?[self.len - 1] = value;
            }
            else {
                self.data = allocator.alloc(T, self.len)
                    catch return Error.OutOfMemory;

                self.data.?[self.len - 1] = value;
            }
        }

        pub inline fn pop(self: *Vec(T)) Error!void {
            if (self.data) |data| {
                self.len -= 1;

                if (self.len != 0) {
                    self.data = allocator.realloc(data, self.len)
                        catch return Error.OutOfMemory;
                }
                else {
                    allocator.free(data);
                    self.data = null;
                }
            }
            else {
                return Error.VecIsEmpty;
            }
        }

        pub inline fn remove(self: *Vec(T), index: usize) Error!void {
            if (index >= self.len)
                return Error.OutOfRange;

            if (self.data) |data| {
                if (index == self.len)
                    try self.pop();

                var temp_array = allocator.alloc(T, self.len)
                    catch return Error.OutOfMemory;
                defer allocator.free(temp_array);

                std.mem.copy(T, temp_array[0..index], self.data.?[0..index]);
                std.mem.copy(T, temp_array[index..self.len - 1], self.data.?[index + 1..self.len]);
                std.mem.copy(T, self.data.?[0..self.len], temp_array[0..self.len]);

                self.len -= 1;

                self.data = allocator.realloc(data, self.len)
                    catch return Error.OutOfMemory;
            }
            else {
                return Error.VecIsEmpty;
            }
        }

        pub inline fn set(self: *Vec(T), index: usize, value: T) Error!void {
            if (index >= self.len)
                return Error.OutOfRange;

            self.data.?[index] = value;
        }

        pub inline fn get(self: *Vec(T), index: usize) Error!T {
            if (index >= self.len)
                return Error.OutOfRange;

            return self.data.?[index];
        }

        pub inline fn get_ptr(self: *Vec(T), index: usize) Error!*T {
            if (index >= self.len)
                return Error.OutOfRange;

            return &self.data.?[index];
        }

        pub inline fn clear(self: *Vec(T)) void {
            self.len = 0;

            if (self.data) |data|
                allocator.free(data);

            self.data = null;
        }

        pub inline fn contains(self: *Vec(T), value: T) bool {
            if (self.data != null) {
                var iter: usize = 0;
                while (iter < self.len) : (iter += 1) {
                    if (self.data.?[iter] == value) {
                        return true;
                    }
                }
            }

            return false;
        }

        pub inline fn insert(self: *Vec(T), _slice: []const T) Error!void {
            if (self.data) |data| {
                self.data = allocator.realloc(data, (self.len + _slice.len))
                    catch return Error.OutOfMemory;

                var iter: usize = self.len;
                while (iter < _slice.len + self.len) : (iter += 1) {
                    self.data.?[iter] = _slice[iter - self.len];
                }

                self.len += _slice.len;
            }
            else {
                self.data = allocator.alloc(T, _slice.len)
                    catch return Error.OutOfMemory;

                var iter: usize = 0;
                while (iter < _slice.len) : (iter += 1) {
                    self.data.?[iter] = _slice[iter];
                }

                self.len = _slice.len;
            }
        }

        pub inline fn append(self: *Vec(T), vec: *Vec(T)) Error!void {
            if (vec.data == null)
                return Error.VecIsEmpty;

            if (self.data) |data| {
                self.data = allocator.realloc(data, (self.len + vec.len))
                    catch return Error.OutOfMemory;

                std.mem.copy(T, self.data.?[self.len..(self.len + vec.len)], vec.data.?[0..vec.len]);

                self.len += vec.len;
            }
            else {
                self.data = allocator.alloc(T, (self.len + vec.len))
                    catch return Error.OutOfMemory;

                std.mem.copy(T, self.data.?[self.len..(self.len + vec.len)], vec.data.?[0..vec.len]);

                self.len = vec.len;
            }
        }

        pub inline fn reverse(self: *Vec(T)) Error!void {
            if (self.data == null)
                return Error.VecIsEmpty;

            var arr = allocator.alloc(T, self.len)
                catch return Error.OutOfMemory;
            defer allocator.free(arr);

            var iter: usize = self.len;
            while (iter > 0) : (iter -= 1) {
                arr[iter - 1] = self.data.?[self.len - iter];
            }

            std.mem.copy(T, self.data.?[0..self.len], arr[0..self.len]);
        }

        pub inline fn swap(self: *Vec(T), f: usize, s: usize) Error!void {
            if (self.data == null)
                return Error.VecIsEmpty;

            if (f >= self.len or s >= self.len)
                return Error.OutOfRange;

            const temp = self.data.?[f]; // using temp value to prevent unsigned vecs to crash program :)
            self.data.?[f] = self.data.?[s];
            self.data.?[s] = temp;
        }

        pub inline fn slice(self: *Vec(T), begin: usize, end: usize) Error![]const T {
            if (begin >= self.len or end >= self.len)
                return Error.OutOfRange;

            if (self.data == null)
                return Error.VecIsEmpty;

            return self.data.?[begin..end + 1];
        }

        pub inline fn clone(self: *Vec(T)) Error!Vec(T) {
            var cloned = Vec(T).init();

            var arr = allocator.alloc(T, self.len)
                catch return Error.OutOfMemory;

            std.mem.copy(T, arr[0..self.len], self.data.?[0..self.len]);

            cloned.data = arr;
            cloned.len = self.len;

            return cloned;
        }

        pub inline fn iterate(self: *Vec(T)) Error![]T {
            if (self.data == null)
                return Error.VecIsEmpty;

            return self.data.?[0..self.len];
        }

        pub inline fn last(self: *Vec(T)) Error!T {
            if (self.len == 0 or self.data == null)
                return Error.VecIsEmpty;

            return self.data.?[self.len - 1];
        }

        pub inline fn first(self: *Vec(T)) Error!T {
            if (self.len == 0 or self.data == null)
                return Error.VecIsEmpty;

            return self.data.?[0];
        }

        pub inline fn last_ptr(self: *Vec(T)) Error!*T {
            if (self.len == 0 or self.data == null)
                return Error.VecIsEmpty;

            return &self.data.?[self.len - 1];
        }

        pub inline fn first_ptr(self: *Vec(T)) Error!*T {
            if (self.len == 0 or self.data == null)
                return Error.VecIsEmpty;

            return &self.data.?[0];
        }

        pub inline fn is_empty(self: *Vec(T)) bool {
            return self.len == 0;
        }

        pub fn debug_print(self: *Vec(T)) void {
            if (self.data != null) {
                std.debug.print("Vec<Type: {}; Len: {}> {{ ", .{ T, self.len });

                var iter: usize = 0;
                while (iter < self.len) : (iter += 1) {
                    std.debug.print("{}", .{ self.data.?[iter] });

                    if (iter < self.len - 1) {
                        std.debug.print(", ", .{});
                    }
                }

                if (iter == self.len) {
                    std.debug.print(" }}\n", .{});
                }
            }
            else {
                std.debug.print("Vec<Type: {}; Len: 0> {{}}\n", .{ T });
            }
        }

        pub fn deinit(self: *Vec(T)) void {
            if (self.data) |data|
                allocator.free(data);
        }

        pub fn delete(self: *Vec(T)) void {
            self.deinit();
        }
    };
}

//       ,'``.._   ,'``.
//      :,--._:)\,:,._,.:       All Glory to
//      :`--,''   :`...';\      the HYPNO TOAD!
//       `,'       `---'  `.
//       /                 :
//      /                   \
//    ,'                     :\.___,-.
//   `...,---'``````-..._    |:       \
//     (                 )   ;:    )   \  _,-.
//      `.              (   //          `'    \
//       :               `.//  )      )     , ;
//     ,-|`.            _,'/       )    ) ,' ,'
//    (  :`.`-..____..=:.-':     .     _,' ,'
//     `,'\ ``--....-)='    `._,  \  ,') _ '``._
//  _.-/ _ `.       (_)      /     )' ; / \ \`-.'
// `--(   `-:`.     `' ___..'  _,-'   |/   `.)
//     `-. `.`.``-----``--,  .'
//       |/`.\`'        ,',');
//           `         (/  (/

test "Vec last && first && last_ptr && first_ptr" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.populate(10, 10);
    try vec.set(0, 20);
    try vec.set(vec.len - 1, 30);

    assert((try vec.last()) == 30);
    assert((try vec.first()) == 20);
    assert((try vec.last_ptr()).* == 30);
    assert((try vec.first_ptr()).* == 20);

    (try vec.last_ptr()).* += 10;
    assert((try vec.last_ptr()).* == 40);

    (try vec.first_ptr()).* += 10;
    assert((try vec.first_ptr()).* == 30);
}

test "Vec iterate" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.push(1);
    try vec.push(2);

    assert(@TypeOf(try vec.iterate()) == []i32);
    assert(vec.len == 2);
}

test "Vec clone" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();
    try vec.populate(10, 10);

    var vec0 = try vec.clone();
    defer vec0.delete();

    assert(vec0.len == 10);
    assert(vec.len == 10);
    assert((try vec.get(0)) == 10);
    assert((try vec0.get(0)) == 10);
}

test "Vec slice" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.populate(0, 10);
    try vec.set(2, 10);

    var slice = try vec.slice(0, 5);

    assert(slice[2] == 10);
}

test "Vec swap" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.push(0);
    try vec.push(10);

    assert((try vec.get(0)) == 0);
    assert((try vec.get(1)) == 10);

    try vec.swap(0, 1);

    assert((try vec.get(0)) == 10);
    assert((try vec.get(1)) == 0);
}

test "Vec reverse" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    var iter: i32 = 10;
    while (iter > 0) : (iter -= 1) {
        try vec.push(iter);
    }

    try vec.reverse();

    assert(vec.len == 10);
    assert((try vec.get(0)) == 1);
    assert((try vec.get(1)) == 2);
    assert((try vec.get(2)) == 3);
    assert((try vec.get(3)) == 4);
    assert((try vec.get(4)) == 5);
    assert((try vec.get(5)) == 6);
}

test "Vec append" {
    const assert = std.debug.assert;

    var vec0 = Vec(bool).new();
    defer vec0.delete();

    try vec0.populate(false, 20);

    var vec1 = Vec(bool).new();
    defer vec1.delete();

    try vec1.append(&vec0);

    assert(vec1.len == 20);
    assert((try vec1.get(2)) == false);
}

test "Vec insert" {
    const assert = std.debug.assert;

    var vec = Vec(u32).new();
    defer vec.delete();

    try vec.insert(&[_]u32 { 32, 17, 24, 12 });

    assert(vec.len == 4);
    assert((try vec.get(0)) == 32);
    assert((try vec.get(1)) == 17);
    assert((try vec.get(2)) == 24);
    assert((try vec.get(3)) == 12);
}

test "Vec contains" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    var iter: i32 = 0;
    while (iter < 20) : (iter += 1) {
        try vec.push(iter);
    }

    assert(vec.contains(13) == true);
    assert(vec.contains(22) == false);
}

test "Vec clear" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.populate(10, 20);

    assert(vec.len == 20);

    vec.clear();

    assert(vec.len == 0);
    assert(vec.data == null);
}

test "Vec get && get_ptr" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.populate(10, 10);

    assert(@TypeOf(try vec.get(1)) == i32);
    assert(@TypeOf(try vec.get_ptr(1)) == *i32);
}

test "Vec set" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.populate(7, 10);
    try vec.set(2, 400);

    assert((try vec.get(2)) == 400);
    assert(vec.len == 10);
}

test "Vec remove" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.populate(1, 10);

    assert(vec.len == 10);

    try vec.remove(9);

    assert(vec.len == 9);
    assert((try vec.get(8)) == 1);
}

test "Vec is_empty" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    assert(vec.is_empty() == true);

    try vec.push(1);

    assert(vec.is_empty() == false);
}

test "Vec pop" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();
    try vec.populate(1, 10);
    try vec.pop();

    assert(vec.len == 9);
}

test "Vec populate" {
    const assert = std.debug.assert;

    {
        var vec = Vec(i32).new();
        defer vec.delete();

        try vec.push(1);
        try vec.populate(17, 9);

        assert(vec.data != null);
        assert(vec.len == 10);
    }
    {
        var vec = Vec(f32).new();
        defer vec.delete();

        try vec.push(1);
        try vec.populate(17, 20);
        try vec.push(3);

        assert(vec.data != null);
        assert(vec.len == 22);
    }
}

test "Vec push" {
    const assert = std.debug.assert;

    var vec = Vec(i32).new();
    defer vec.delete();

    try vec.push(1);

    assert(vec.data != null);
    assert(vec.len == 1);
}

test "Vec init and defer" {
    const assert = std.debug.assert;

    // integers
    {
        var v0 = Vec(i8).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]i8);

        var v1 = Vec(i8).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]i8);
    }
    {
        var v0 = Vec(i16).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]i16);

        var v1 = Vec(i16).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]i16);
    }
    {
        var v0 = Vec(i32).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]i32);

        var v1 = Vec(i32).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]i32);
    }
    {
        var v0 = Vec(i64).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]i64);

        var v1 = Vec(i64).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]i64);
    }
    {
        var v0 = Vec(i128).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]i128);

        var v1 = Vec(i128).new();
        defer v1.delete();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]i128);
    }

    // unsigned integers
    {
        var v0 = Vec(u8).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]u8);

        var v1 = Vec(u8).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]u8);
    }
    {
        var v0 = Vec(u16).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]u16);

        var v1 = Vec(u16).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]u16);
    }
    {
        var v0 = Vec(u32).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]u32);

        var v1 = Vec(u32).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]u32);
    }
    {
        var v0 = Vec(u64).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]u64);

        var v1 = Vec(u64).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]u64);
    }
    {
        var v0 = Vec(u128).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]u128);

        var v1 = Vec(u128).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]u128);
    }

    // isize, usize
    {
        var v0 = Vec(isize).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]isize);

        var v1 = Vec(isize).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]isize);
    }
    {
        var v0 = Vec(usize).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]usize);

        var v1 = Vec(usize).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]usize);
    }

    // c types
    {
        var v0 = Vec(c_short).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_short);

        var v1 = Vec(c_short).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_short);
    }
    {
        var v0 = Vec(c_ushort).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_ushort);

        var v1 = Vec(c_ushort).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_ushort);
    }
    {
        var v0 = Vec(c_int).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_int);

        var v1 = Vec(c_int).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_int);
    }
    {
        var v0 = Vec(c_uint).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_uint);

        var v1 = Vec(c_uint).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_uint);
    }
    {
        var v0 = Vec(c_long).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_long);

        var v1 = Vec(c_long).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_long);
    }
    {
        var v0 = Vec(c_ulong).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_ulong);

        var v1 = Vec(c_ulong).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_ulong);
    }
    {
        var v0 = Vec(c_longlong).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_longlong);

        var v1 = Vec(c_longlong).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_longlong);
    }
    {
        var v0 = Vec(c_ulonglong).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_ulonglong);

        var v1 = Vec(c_ulonglong).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_ulonglong);
    }
    {
        var v0 = Vec(c_longdouble).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]c_longdouble);

        var v1 = Vec(c_longdouble).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]c_longdouble);
    }

    // boolean
    {
        var v0 = Vec(bool).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]bool);

        var v1 = Vec(bool).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]bool);
    }
    
    // floating point variables
    {
        var v0 = Vec(f16).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]f16);

        var v1 = Vec(f16).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]f16);
    }
    {
        var v0 = Vec(f32).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]f32);

        var v1 = Vec(f32).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]f32);
    }
    {
        var v0 = Vec(f64).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]f64);

        var v1 = Vec(f64).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]f64);
    }
    {
        var v0 = Vec(f128).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]f128);

        var v1 = Vec(f128).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]f128);
    }
    {
        var v0 = Vec(f80).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]f80);

        var v1 = Vec(f80).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]f80);
    }

    // user defined structures
    {
        const T0 = struct {
            value: i32,
        };

        var v0 = Vec(T0).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]T0);

        var v1 = Vec(T0).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]T0);
    }
    {
        const T0 = packed struct {
            value: i32,
        };

        var v0 = Vec(T0).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]T0);

        var v1 = Vec(T0).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]T0);
    }
    {
        const T0 = enum {
            enum_value,
            @"something shown in official documentation",
        };

        var v0 = Vec(T0).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]T0);

        var v1 = Vec(T0).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]T0);
    }
    {
        const T0 = union {
            value0: f32,
            value1: i32,
        };

        var v0 = Vec(T0).init();
        defer v0.deinit();
        assert(v0.len == 0);
        assert(@TypeOf(v0.data) == ?[]T0);

        var v1 = Vec(T0).new();
        defer v1.delete();
        assert(v1.len == 0);
        assert(@TypeOf(v1.data) == ?[]T0);
    }
}
