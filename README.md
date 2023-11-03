# DependantCollections
Swift collection types that support efficient storage of order-relative values

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/DependantCollections", branch: "main")
]
```

## Concepts

All the structures here store relative data. This means that a given value has some kind of dependency on the values that came before. If you're data fits into this model, it can help to improve the efficiency of certain operations.

These are very similar in concept to a [Rope](https://en.wikipedia.org/wiki/Rope_(data_structure)). And while these structures are just a little more generalized, the terminology used is similar. Data is split into two components: `Value` and `Weight`. The `Value` is independent data. The `Weight` is the per-element contribution. The full element is reconstructed by combining all preceding elements `Weight`, along with its independent `Value`.

To operate on the `Weight`, these collections need user-defined functions to perform addition, subtraction, as well as finding an initial value. However, if `Weight` conforms to the `AdditiveArithmetic` protocol, these can all be inferred.

## Usage

Let's take a look at some real-world usage of a structure like this. Consider an application that works with text and needs to store information about each line in a document. You might just record the range of each line as `(start, length)`. This presents a problem when the text changes. Because the `start` value is absolute, you have update all subsequent entries on an edit.

This is a great example of relative data! The `length` is the independent value. As long as an edit does not occur within the line, a `length` is not affected by edits. The relative value is the `start` - it is defined as the sum of all preceding lengths.

Here, `Metrics` is a type that stores information about a line of text. You could put all kinds of stuff in here, like the height of a line, if it contains any non-UTF-8 data. But, let's keep it simple and just record offsets to any leading and trailing whitespace.

This `Metrics` type will be our independent `Value`. Line length, expressed as an `Int` with make up the relative `Weight`. This works because a line's absolute starting position is the sum of all preceding line lengths.

```swift
struct Metrics {
    let leadingWhitespace: Int
    let trailingWhitespace: Int
    
    init(_ leading: Int, trailing: Int) {
        self.leadingWhitespace = leading
        self.trailingWhitespace = trailing
    }
}
```

To get this working, we also need to define a few core operations on the `Weight`. You can do that through a `Configuration` property.

```swift
let config = DependantArray<Metrics, Int>.Configuration(
    initial: 0,
    add: { lengthA, lengthB in lengthA + lengthB },
    subtract:  lengthA, lengthB in lengthA - lengthB }
)
```

All this ceremony allows for very abstract `Weight` types. However, we can do better for types that implement `AdditiveArithmetic`, which `Int` does! In that case, `Configuration` has predefined behavior that will automatically do the right thing. Making your own custom types conform to `AdditiveArithmetic` will allow it to work the same way.

This allows us to define a configuration with a default initializer. And, this is also set as a default for `DependantArray`, so in this case we can avoid dealing with configuration entirely.

On to some example data! Let's say we'd like to store metrics for this text:

```
   abc   
  defghi
 jk
```

We can do that by creating our array with the right types and appending some `WeightedValue` types in.

```swift
let array = DependantArray<Metrics, Int>()

array.append(
    WeightedValue(value: Metrics(3, 3), weight: 9),
)

array.append(
    WeightedValue(value: Metrics(2, 0), weight: 8),
)

array.append(
    WeightedValue(value: Metrics(1, 0), weight: 3),
)

```

Now that our data is loaded, we can read out values. And with a little work, we can reconstruct our desired values.

```swift
let record = array[2]

let start = record.dependency // 17 (9 + 8)
let length = record.weight    // 3
let metrics = record.value.   // Metrics(1, 0)
```

## Structures

### `DependantArray`

A `DependantArray` is the simplest type. It stores a `Value` and `Weight` in a plain array. On its own, this type can be handy for many applications. But, it is also used as a building block for more complex structures.

`DependantArray` conforms to `Sequence` and `RandomAccessCollection`. It supports CoW, just like other Swift collections.

### `DependantList`

This is a position-addressable type, like an array. However, internally it stores data in a [B+Tree](https://en.wikipedia.org/wiki/B%2B_tree). That gets you logarithmic insertion and deletion.

`DependantList` conforms to `Sequence` and `RandomAccessCollection`.

However, this is a reference type and does not support CoW. I started looking into it more, but just getting this to work was hard enough.

### Notes on Data Structures

You might be wondering why I didn't use a [Red-black tree](https://en.wikipedia.org/wiki/Red–black_tree) for this. Red-black tree's are great! They may be the simplest self-balancing tree structure known. And, they can totally be used in this relative-data context. However, they do make some trade-offs. Compared to something like a [B-tree](https://en.wikipedia.org/wiki/B-tree), they need a lot more pointers. This adds to memory overhead and isn't great for locality of reference. This is basically why B-Tree's were invented in the first place. They also will compare unfavorably to an array for small N. And as they say, N is usually small. A B+Tree addresses both these limitations, though of course it is a lot more complex internally.

At one point, I got excited about trying out a [skip list](https://en.wikipedia.org/wiki/Skip_list) for this, because skip lists are cool. I had a tough time getting my head around how to do this at all, and skip lists just made it harder.

Typically, when faced with this kind of problem you have to measure. Carefully. But, the allure of optimization-without-rigor is powerful and I gave in. I don't know if this structure is actually faster than a RBTree or standard B-Tree. But I learned a lot. I hope that one day [Swift Collections](https://github.com/apple/swift-collections) provides a suitable B+Tree or Rope.

## Related Projects

- [The Swift Algorithm Club](https://github.com/kodecocodes/swift-algorithm-club)
- [SummarizedCollection](https://github.com/jessegrosjean/SummarizedCollection)
- [Swift Collections](https://github.com/apple/swift-collections)

## Contributing and Collaboration

I'd love to hear from you! Get in touch via an issue or pull request.

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).
