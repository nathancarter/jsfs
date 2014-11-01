
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

## Errors are thrown if compression tools are needed but absent

We move the `LZString` object off to the side temporarily.  Then try to save
a file in a filesystem without compression, and ensure that no errors are
thrown.  Then try to save a file in that filesystem with compression, and
ensure that errors are thrown.

        it 'throws errors if compression tools are needed but absent', ->

First we write a compressed file, so that later we can test reading on it.

            F = new window.FileSystem 'example'
            expect( -> F.write 'compressed.txt', 'contents here', yes )
                .not.toThrowError()

Now we move the `LZString` tools off to the side temporarily.

            saveLZString = window.LZString
            window.LZString = null

Then we attempt to save a file in a filesystem using compression.  This
should generate an error.

            expect( -> F.write 'test.txt', 'contents here', yes )
                .toThrowError 'Cannot compress file; LZString undefined'

Do the same with attempting to read a file.  Expect a corresponding error.

            expect( -> F.read 'compressed.txt' )
                .toThrowError 'Cannot decompress file; LZString undefined'

Now put things back the way they were beforehand, so that future tests have
access to `LZString` as it was before.

            window.LZString = saveLZString
            saveLZString = null

## Compression functions are called from read and write

Here we overwrite the `LZString` compression and decompression functions
with tools of our own that just verify whether they were called or not,
returning the content unchanged.  We use these tools to verify that the
compression tools are actually getting called if and only if we enable
compression.

        it 'calls compression functions if and only if asked to', ->

First we create a fake compression function and a fake decompression
function.  These do nothing (identity functions) except have the
side-effects of marking themselves as having been called.

            fakeCompressionFunctionCalled = no
            fakeCompressionFunction = ( x ) ->
                fakeCompressionFunctionCalled = yes
                x
            fakeDecompressionFunctionCalled = no
            fakeDecompressionFunction = ( x ) ->
                fakeDecompressionFunctionCalled = yes
                x

We now install them in place of the correct ones, archiving the correct ones
for later restoration.

            saveCompress = LZString.compress
            saveDecompress = LZString.decompress
            LZString.compress = fakeCompressionFunction
            LZString.decompress = fakeDecompressionFunction

We now verify that these functions have not yet been called.

            expect( fakeCompressionFunctionCalled ).toBeFalsy()
            expect( fakeDecompressionFunctionCalled ).toBeFalsy()

Even if we create a filesystem and write files to disk, these functions are
still not called, because we did not use compression.

            F = new window.FileSystem 'example'
            expect( -> F.write 'test.txt', 'some content' )
                .not.toThrowError()
            expect( fakeCompressionFunctionCalled ).toBeFalsy()
            expect( fakeDecompressionFunctionCalled ).toBeFalsy()

But if we write some a file to disk compressed, then the compression
function (alone) will have been called.

            expect( -> F.write 'test.txt', 'some content', yes )
                .not.toThrowError()
            expect( fakeCompressionFunctionCalled ).toBeTruthy()
            expect( fakeDecompressionFunctionCalled ).toBeFalsy()

We then reset its flag to false, read from the compressed file, and find
that only the fake decompression function has been called.

            fakeCompressionFunctionCalled = no
            tmp = null
            expect( -> tmp = F.read 'test.txt' ).not.toThrowError()
            expect( tmp ).toEqual 'some content'
            expect( fakeCompressionFunctionCalled ).toBeFalsy()
            expect( fakeDecompressionFunctionCalled ).toBeTruthy()

Then restore the original compress and decompress for use in later testing.

            LZString.compress = saveCompress
            LZString.decompress = saveDecompress

## Compression makes files smaller

        it 'make compressed files smaller than uncompressed ones', ->

We create here a few objects that we will write to storage, and the
filesystem in which to store them.

            objectsToWrite = [
                {
                    key1 : [ 1, 2, 3, 7, 8, 9 ]
                    key2 : "this is string content"
                    key3 : { hamster : no }
                }
                "Four score and seven years ago, our forefathers brought
                forth on this continent a new nation, conceived in liberty,
                and dedicated to the proposition that all men are created
                equal."
                [ [ ], [ "" ], [ " ", [ " " ] ], { }, { } ]
            ]
            F = new window.FileSystem 'example'

Write each file to disk uncompressed and get its size.  Verify that it is
positive.

            sizesUncompressed = [
                F.write 'object0.dat', objectsToWrite[0], no
                F.write 'object1.dat', objectsToWrite[1], no
                F.write 'object2.dat', objectsToWrite[2], no
            ]
            expect( sizesUncompressed[0] ).toBeGreaterThan 0
            expect( sizesUncompressed[1] ).toBeGreaterThan 0
            expect( sizesUncompressed[2] ).toBeGreaterThan 0

Write each file to disk compressed and get its size.  Verify that it is
smaller than the original.

            sizesCompressed = [
                F.write 'object0.zip', objectsToWrite[0], yes
                F.write 'object1.zip', objectsToWrite[1], yes
                F.write 'object2.zip', objectsToWrite[2], yes
            ]
            expect( sizesCompressed[0] ).toBeLessThan sizesUncompressed[0]
            expect( sizesCompressed[1] ).toBeLessThan sizesUncompressed[1]
            expect( sizesCompressed[2] ).toBeLessThan sizesUncompressed[2]

## Compressed files can still be read accurately

        it 'can reread compressed data written to storage', ->

We create here a few objects that we will write to storage, and the
filesystem in which to store them.  These are the same objects used in the
previous test.

            objectsToWrite = [
                {
                    key1 : [ 1, 2, 3, 7, 8, 9 ]
                    key2 : "this is string content"
                    key3 : { hamster : no }
                }
                "Four score and seven years ago, our forefathers brought
                forth on this continent a new nation, conceived in liberty,
                and dedicated to the proposition that all men are created
                equal."
                [ [ ], [ "" ], [ " ", [ " " ] ], { }, { } ]
            ]
            F = new window.FileSystem 'example'

Write each file to disk compressed and get its size.  Verify that it is
greater than zero.

            expect( F.write 'object0.zip', objectsToWrite[0], yes )
                .toBeGreaterThan 0
            expect( F.write 'object1.zip', objectsToWrite[1], yes )
                .toBeGreaterThan 0
            expect( F.write 'object2.zip', objectsToWrite[2], yes )
                .toBeGreaterThan 0

Reread each file from disk and verify that it deserialized into an object
equivalent to the original stored object.

            expect( F.read 'object0.zip' ).toEqual objectsToWrite[0]
            expect( F.read 'object1.zip' ).toEqual objectsToWrite[1]
            expect( F.read 'object2.zip' ).toEqual objectsToWrite[2]

## Respects the compression default stored in the instance

        it 'respect the compression default in the FileSystem instance', ->

Create the same objects used in the last two tests, and a `FileSystem`
instance.

            objectsToWrite = [
                {
                    key1 : [ 1, 2, 3, 7, 8, 9 ]
                    key2 : "this is string content"
                    key3 : { hamster : no }
                }
                "Four score and seven years ago, our forefathers brought
                forth on this continent a new nation, conceived in liberty,
                and dedicated to the proposition that all men are created
                equal."
                [ [ ], [ "" ], [ " ", [ " " ] ], { }, { } ]
            ]
            F = new window.FileSystem 'example'

Write the objects to disk three times, once with the default not set to any
value (to test that it is initially set to uncompressed), once with the
default explicitly set to uncompressed writing, writing, and once with it
set to compressed writing.

            expect( F.write 'object0a.dat', objectsToWrite[0] )
                .toBeGreaterThan 0
            expect( F.write 'object1a.dat', objectsToWrite[1] )
                .toBeGreaterThan 0
            expect( F.write 'object2a.dat', objectsToWrite[2] )
                .toBeGreaterThan 0
            F.compressionDefault = no
            expect( F.write 'object0b.dat', objectsToWrite[0] )
                .toBeGreaterThan 0
            expect( F.write 'object1b.dat', objectsToWrite[1] )
                .toBeGreaterThan 0
            expect( F.write 'object2b.dat', objectsToWrite[2] )
                .toBeGreaterThan 0
            F.compressionDefault = yes
            expect( F.write 'object0c.dat', objectsToWrite[0] )
                .toBeGreaterThan 0
            expect( F.write 'object1c.dat', objectsToWrite[1] )
                .toBeGreaterThan 0
            expect( F.write 'object2c.dat', objectsToWrite[2] )
                .toBeGreaterThan 0

Verify that the sizes of the "a" and "b" files are the same, demonstrating
that they were either both compressed or both uncompressed. (We verify below
that they were the uncompressed versions.)

            expect( F.size 'object0a.dat' ).toBe F.size 'object0b.dat'
            expect( F.size 'object1a.dat' ).toBe F.size 'object1b.dat'
            expect( F.size 'object2a.dat' ).toBe F.size 'object2b.dat'

Verify that the "a" files are larger than the "c" files, demonstrating that
the "c" files must be the compressed ones, while the "a" files are
uncompressed.  (Because the "a" and "b" files are the same sizes, this also
means that "b" files are uncompressed.)

            expect( F.size 'object0a.dat' )
                .toBeGreaterThan F.size 'object0c.dat'
            expect( F.size 'object1a.dat' )
                .toBeGreaterThan F.size 'object1c.dat'
            expect( F.size 'object2a.dat' )
                .toBeGreaterThan F.size 'object2c.dat'
