
# FileSystem Class Tests

These tests are about instances of the `FileSystem` class, and
thus this will be where the majority of the tests for this
repository lie.

    describe 'Each FileSystem instance', ->

## Setup and cleanup

The tests in this section create a lot of file systems, each of
which gets written to the browser's LocalStorage.  Not only is
this spammy, but it can confound the results of future runs of
the same test sutie.  For this reason, we list here all the names
of example filesystems used throughout this test, and the maximum
number of files we might create in each, for use in setup/cleanup
functions.

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

And the final line of the cleaning function is completely
dangerous to use if any `FileSystem` objects exist!  But we will
only be using it between tests, where we will not be retaining
any such objects.

            window.FileSystem::_cache = { }

We install it as both setup and cleanup for each test run below.

        beforeEach completeClear
        afterEach completeClear

## The tests themselves

Ensure it accepts a name parameter and retains it internally,
allowing it to be queried by the `getName` member function.

        it 'retains the name with which it\'s constructed', ->
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

If two are constructed with the same name, they should share the
same internal filesystem object.  This suggests that the cache is
working.  Similarly, two with different names should not share
data.  This test requires reaching in to access a private member
within the instances, but this is the easiest and most direct
test.

        it 'with the same name shares one filesystem object', ->
            F = new window.FileSystem 'example'
            G = new window.FileSystem 'example'
            expect( F._getFilesystemObject() ).toBe(
                    G._getFilesystemObject() )
            H = new window.FileSystem 'other'
            expect( F._getFilesystemObject() ).not.toBe(
                    H._getFilesystemObject() )
            expect( G._getFilesystemObject() ).not.toBe(
                    H._getFilesystemObject() )

We first test that the private member for writing to LocalStorage
works in simple cases where nothing goes wrong.

        it 'supports writing with _changeFileSystem', ->
            F = new window.FileSystem 'example'
            F._changeFileSystem ( fs ) -> fs.newFolder = { }
            result = JSON.parse \
                localStorage.getItem F._storageName()
            expect( result ).toEqual newFolder : { }

Now we test that if we attempt to change the filesystem in a way
that causes an error, no changes are recorded because the object
immediately restores the original version from backup.

        it 'supports writing safely even through errors', ->

First, create a `FileSystem` object and run a null change to
induce a save to LocalStorage.

            F = new window.FileSystem 'example'
            F._changeFileSystem ( fs ) ->

Now a simple test to verify the baseline.  We check both the
in-memory version of the filesystem and the in-storage version.

            result = JSON.parse \
                localStorage.getItem F._storageName()
            expect( result ).toEqual { }
            expect( F._getFilesystemObject() ).toEqual { }

Now make a change that will first edit the filesystem, then throw
an error.

            error = null
            try
                F._changeFileSystem ( fs ) ->
                    fs.change = { }
                    throw new Error 'Oops!'
            catch e
                error = e

Verify that the error was propagated out of the change call.

            expect( error ).not.toBeNull()
            expect( error.message ).toEqual 'Oops!'

Verify that we're back to the baseline state; no change happened
to the filesystem at all.  Again, we check both memory and the
LocalStorage.

            result = JSON.parse \
                localStorage.getItem F._storageName()
            expect( result ).toEqual { }
            expect( F._getFilesystemObject() ).toEqual { }

