
These tests are about the `FileSystem` class itself, as opposed to
instances thereof.

    describe 'FileSystem class', ->

Ensure the global variable `FileSystem` is defined.

        it 'should be defined', ->
            expect( window.FileSystem ).toBeTruthy()

