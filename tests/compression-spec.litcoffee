
# Testing Compression Features of the FileSystem Class

An optional feature of `FileSystem` class instances is data compression.
That feature applies the compression algorithm in
[lz-string](http://pieroxy.net/blog/pages/lz-string/index.html) to data
before writing it to a file, and the corresponding decompression to the file
upon reading the data back out.

These features require the user to import the `lz-string-1.3.3.js` file into
the same webpage in which they use `jsfs.js`, or errors will be thrown when
the `LZString` object is not available to jsfs.

    describe 'Compression features of the FileSystem class', ->

## Setup and cleanup

The cleanup functions here are taken directly from those in
[instance-spec.litcoffee](instance-spec.litcoffee).  See that file for
documentation.

        allNamesUsed = [
            'hello there'
            '2'
            'undefined'
            'example'
            'other'
        ]
        maxNumFilesCreatedInEach = 10

Here is the cleaning function.

        completeClear = ->
            for name in allNamesUsed
                localStorage.removeItem "#{name}_filesystem"
                for i in [0...10]
                    localStorage.removeItem "#{name}_file_#{i}"

We install it as both setup and cleanup for each test run below.

        beforeEach completeClear
        afterEach completeClear

## Errors are thrown if compression is needed but absent

Tests still to be written

## Compression functions are called from read and write

Tests still to be written

## Compression makes files smaller

Tests still to be written

## Compressed files can still be read accurately
