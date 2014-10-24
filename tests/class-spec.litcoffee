
These tests are about the `FileSystem` class itself, as opposed to
instances thereof.

    describe 'The FileSystem class', ->

Ensure the global variable `FileSystem` is defined.

        it 'is defined', ->
            expect( window.FileSystem ).toBeTruthy()

Ensure it has the class members it provides, functioning as a
namespace.

        it 'provides class members like a namespace does', ->
            expect( window.FileSystem::pathSeparator ).toBeTruthy()
            expect( window.FileSystem::escapeCharacter )
                .toBeTruthy()

Test the path-splitting routine stored in the `FileSystem` class.

        it 'provides a working path-splitting function', ->

First, simple splits with no escape characters, first relative,
then absolute, then with `.` and `..` codes.

            expect( FileSystem::_splitPath 'abc/def' ).toEqual \
                [ 'abc', 'def' ]
            expect( FileSystem::_splitPath '/ab/cd/ef' ).toEqual \
                [ 'ab', 'cd', 'ef' ]
            expect( FileSystem::_splitPath '/ab/./ef' ).toEqual \
                [ 'ab', '.', 'ef' ]
            expect( FileSystem::_splitPath 'ab/../ef' ).toEqual \
                [ 'ab', '..', 'ef' ]

Second, splits that have some escape characters in them.

            expect( FileSystem::_splitPath 'you\\/me/stuff' ) \
                .toEqual [ 'you/me', 'stuff' ]
            expect( FileSystem::_splitPath 'latex/\\\\mathbb' ) \
                .toEqual [ 'latex', '\\mathbb' ]
            expect( FileSystem::_splitPath \
                '\\/tex/\\\\in/3\\\\Z' ) \
                .toEqual [ '/tex', '\\in', '3\\Z' ]

In reverse, we take the exact same examples, and try to path-join
them, and ensure that they recreate the original inputs.

            expect( FileSystem::_joinPath [ 'abc', 'def' ] ) \
                .toEqual 'abc/def'
            expect( FileSystem::_joinPath [ 'ab', 'cd', 'ef' ] ) \
                .toEqual 'ab/cd/ef'
            expect( FileSystem::_joinPath [ 'ab', '.', 'ef' ] ) \
                .toEqual 'ab/./ef'
            expect( FileSystem::_joinPath [ 'ab', '..', 'ef' ] ) \
                .toEqual 'ab/../ef'
            expect( FileSystem::_joinPath [ 'you/me', 'stuff' ] ) \
                .toEqual 'you\\/me/stuff'
            expect( FileSystem::_joinPath \
                [ 'latex', '\\mathbb' ] ) \
                .toEqual 'latex/\\\\mathbb'
            expect( FileSystem::_joinPath \
                [ '/tex', '\\in', '3\\Z' ] ) \
                .toEqual '\\/tex/\\\\in/3\\\\Z'

Finally, be sure that the two functions in succession do not
change any input string.

            example = 'fk\\\\js/j/fja\\\\dslfj\\/fs'
            expect( FileSystem::_joinPath FileSystem::_splitPath \
                example ).toEqual example
            example = [
                'jd/kfj\\'
                'jfk/\\d/jd'
                'fdj/sk\\lf'
            ]
            expect( FileSystem::_splitPath FileSystem::_joinPath \
                example ).toEqual example

One more small test:  Multiple path separators in a row should
just become one.

            expect( FileSystem::_splitPath '//ab//ef' ).toEqual \
                [ 'ab', 'ef' ]
            expect( FileSystem::_splitPath '//ab////ef' ).toEqual \
                [ 'ab', 'ef' ]

