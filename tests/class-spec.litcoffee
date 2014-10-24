
These tests are about the `FileSystem` class itself, as opposed to
instances thereof.

    describe 'FileSystem class', ->

Ensure the global variable `FileSystem` is defined.

        it 'is defined', ->
            expect( window.FileSystem ).toBeTruthy()

Ensure it has the class members it provides, functioning as a
namespace.

        it 'provides class members like a namespace does', ->
            expect( window.FileSystem::pathSeparator ).toBeTruthy()
            expect( window.FileSystem::escapeCharacter )
                .toBeTruthy()

