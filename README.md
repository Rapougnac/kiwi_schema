# kiwi_schema

A parser, encoder & decoder for [Kiwi](https://github.com/evanw/kiwi), a schema-based binary format for efficiently encoding trees of data.

# Example
See the [example](./example/) directory.


# Informations

### Why [u]int64 are typed as `int`s in Dart?
__**Because `int`s are based 🗿.**__

Seriously, Dart's `int`s are 64-bits by default, the only problem comes if you compile your dart code to JS. As it cannot handles ints larger than 32 bits.

_But no ones really compile dart code to js, right, right??_

If you absolutely want to add/use js, use the js/ts wrapper natively provided by [Kiwi](https://github.com/evanw/kiwi/blob/master/examples/js.md)

### Why?
I was bored and didn't know what to do, soo, yeah, nobody will use it but idc, that was fun.

(Also that's my first useful package, heh)


# Credits
- Evan Wallace, the original creator of Kiwi.
