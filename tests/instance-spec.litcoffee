
These tests are about instances of the `FileSystem` class, and
thus this will be where the majority of the tests for this
repository lie.

    describe 'FileSystem instances', ->

Ensure it accepts a name parameter and retains it internally,
allowing it to be queried by the `getName` member function.

        it 'retain the name with which they\'re constructed', ->
            F = new window.FileSystem 'hello there'
            expect( F.getName() ).toEqual 'hello there'
            F = new window.FileSystem 2
            expect( F.getName() ).toEqual '2'
            F = new window.FileSystem ''
            expect( F.getName() ).toEqual 'undefined'
            F = new window.FileSystem []
            expect( F.getName() ).toEqual 'undefined'
            F = new window.FileSystem()
            expect( F.getName() ).toEqual 'undefined'

