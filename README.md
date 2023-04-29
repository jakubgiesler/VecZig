# VecZig
Zig implementation of Vectors.
###### Used Zig version v0.10.1
###### Library version 0.2.0
```markdown
> About
```
 - Storing any Zig and C variables inside Vec including Structs, Unions and Enums on heap
 - Super simple iteration 
 - Automatic memory allocations, reallocations
 - Uses `c allocator` by default, no need to pass allocator
  ```markdown
> Note
```
This library is not meant to be a replacement for ArrayList in STD, but rather an alternative.
Also, this library is young (see lib version above) and not meant to be in production yet.
 ```markdown
> Planned features
```
- [ ] Sorting by value or by passed custom function pointer
- [ ] Preallocating memory with pre-defined capacity and reserve more if needed
- [ ] Retain
- [ ] Ability to choose if use `c_allocator` or not
- [ ] Reversing in specific range
- [ ] Swap remove
- [ ] Proper documentation
- [ ] Find, Filter, Flatten, Map and more planned.
## Usage example
```zig
// build.zig
exe.linkLibC();
exe.addPackage(std.build.Pkg { .name = "vec", .source = std.build.FileSource { .path = "path_to_pkg/VecZig/src/main.zig" } });
```
- Then you can anywhere use
```zig
// main.zig
const Vec = @import("vec").Vec;

fn main() !void {
	var vec = Vec.new();
	defer vec.delete();
	// ...
}
```
## Docs?

#### Creating new Vec examples

```zig
var vector0 = Vec(type).init();
var vector1 = Vec(i32).init();

// or can be initalized with
var vector2 = Vec(f32).new();

const MY_STRUCT = struct {
	data: i32,
};

var vector3 = Vec(MY_STRUCT).new();
```
#### Freeing Vec
```zig
defer vec0.deinit();

// or can be freed with
defer vec1.delete();
```
#### Pushing new elements
```zig
try vector1.push(1);
try vector3.push(MY_STRUCT { .data = 13, });
```
#### Push same value n times
```zig
// n times --------------\
// value ------------\   |
//                   |   |
try vector1.populate(10, 10);
```
#### Print entire content of Vec into Terminal
```zig
vector1.debug_print();
```
#### Iterate through elements
```zig
for (try  vec.iterate()) |element| {
	print("{}", .{ element });
}

// or by pointer which you can edit
for (try  vec.iterate()) |*element| {
	element.* += 1;
	
	print("{}", .{ element });
}
```
#### Getting length of Vec
```zig
var length = vector1.len;
```
#### Check if Vec is empty with
```zig
if (vector1.is_empty()) {
	print("Yes its empty", .{});
}
```
#### Removing last element
```zig
try vector1.pop();
```
#### Removing element by index
```zig
try vector1.remove(3);
```
#### Edit value by index
```zig
// new value -------\
// index -------\   |
//              |   |
try vector1.set(10, 100);
```
#### Getting value by index
```zig
try vector1.get(10);
```
#### Getting pointer to value by index
```zig
try vector1.get_ptr(10);
```
#### Clearing entire array
```zig
vector1.clear();
```
#### Checking if Vec contains value
```zig
var result = vector1.contains(13);
```
#### Pushing slices
```zig
try vector1.insert(&[_] i32 { 1, 2, 3, 4, 5 });
```
#### Concat another arrays with same type
```zig
try vector1.append(another_vector);
```
#### Reversing order 
```zig
try vector1.reverse();
```
#### Truncate -> shortens the vector
```zig
try vector1.truncate(5);
```
#### Drain -> Removes range from array and returns it as slice
```zig
var slice = try vector1.drain(5, 7);
```
#### Swaping values by indexes
```zig
try vector1.swap(0, 3);
```
#### Getting slice -> slices are returned as Vec(T)
```zig
// end at -------------------\
// begin at --------------\  |
//                        |  |
var slice = vector1.slice(0, 5);
defer slice.delete();
```
#### Cloning Vec
```zig
var new_vector = vector1.clone();
```
#### Getting last / first values
```zig
var first = try vector1.first();
var last = try vector1.last();
```
#### Getting last / first pointers
```zig
var first = try vector1.first_ptr();
var last = try vector1.last_ptr();
```



