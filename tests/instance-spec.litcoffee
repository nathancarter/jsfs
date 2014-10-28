
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

## The constructor

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

## Storage

We first test that the private member for writing to LocalStorage
works in simple cases where nothing goes wrong.

        it 'supports writing with _changeFilesystem', ->
            F = new window.FileSystem 'example'
            F._changeFilesystem ( fs ) -> fs.newFolder = { }
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
            F._changeFilesystem ( fs ) ->

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
                F._changeFilesystem ( fs ) ->
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

## Changing the working directory

Running these tests also indirectly tests the routine that detects
valid vs. invalid canonical paths.

        it 'can change the cwd correctly', ->
            F = new window.FileSystem 'example'
            F._changeFilesystem ( fs ) ->
                fs.folder1 = inner1a : { }, inner1b : { }
                fs.folder2 = inner2a : { }

The above lines of code make the following file hierarchy, for
use in the tests below.
 * folder1
   * inner1a
   * inner1b
 * folder2
   * inner2a


Try to `cd` to the root folder in two ways.

            F.cd()
            expect( F._cwd ).toBe '/'
            F.cd '/'
            expect( F._cwd ).toBe '/'

Try an absolute path, a non-canonical path, and a relative path.

            F.cd '/folder1'
            expect( F._cwd ).toBe '/folder1'
            F.cd '..'
            expect( F._cwd ).toBe '/'
            F.cd 'folder1'
            expect( F._cwd ).toBe '/folder1'

Try a few nested paths, but all still valid.

            F.cd 'inner1a'
            expect( F._cwd ).toBe '/folder1/inner1a'
            F.cd '../inner1b'
            expect( F._cwd ).toBe '/folder1/inner1b'
            F.cd '../../'
            expect( F._cwd ).toBe '/'
            F.cd 'folder2/inner2a'
            expect( F._cwd ).toBe '/folder2/inner2a'
            F.cd '../../folder1'
            expect( F._cwd ).toBe '/folder1'
            F.cd '/folder2'
            expect( F._cwd ).toBe '/folder2'
            F.cd '/folder1/nothing/..'
            expect( F._cwd ).toBe '/folder1'

Now try some invalid paths.  In each case, the cwd should not
change, because the attempted `cd` call was to an invalid folder.

            F.cd 'foo'
            expect( F._cwd ).toBe '/folder1'
            F.cd '../folder3'
            expect( F._cwd ).toBe '/folder1'
            F.cd 'folder1'
            expect( F._cwd ).toBe '/folder1'
            F.cd 'foo/bar/..'
            expect( F._cwd ).toBe '/folder1'

## Creating new folders

        it 'can use mkdir to make new folders', ->
            F = new window.FileSystem 'example'

First be sure that /foo does not exist.  Then create it and cd
into it, and verify that we have entered it.  Also verify that
the `mkdir` call returns true.

            F.cd 'foo'
            expect( F._cwd ).toBe '/'
            expect( F.mkdir 'foo' ).toBeTruthy()
            F.cd 'foo'
            expect( F._cwd ).toBe '/foo'

Now repeat the same test, but this time for a more deeply nested
path, and test that we can cd into each part of it.

            expect( F.mkdir '/bar/baz' ).toBeTruthy()
            F.cd '/bar'
            expect( F._cwd ).toBe '/bar'
            F.cd 'baz'
            expect( F._cwd ).toBe '/bar/baz'

Now verify that `mkdir` returns false if the directory already
exists.

            expect( F.mkdir '/foo' ).toBeFalsy()
            expect( F.mkdir '/bar' ).toBeFalsy()

## Reading and writing files

This tests the file-related functions `read`, `write`, and
`append`, all of which are used on instances of the `FileSystem`
class, and modify files (not folders).

Throughout this set of tests, we also record file sizes and
verify that they are greater than zero on every return from a
write operation, and that `fs.size` called subsequently returns
the same size that the write operation did.  We do not check the
actual string lengths, because these depend on serialization
techniques, and we do not want such dependencies hard-coded into
this test suite.

        it 'can read and write files to and from storage', ->
            F = new window.FileSystem 'example'

Write some text to a file and ensure it can be re-read.

            fname = 'bar.txt'
            content = 'just a string'
            size = F.write fname, content
            expect( size ).toBeGreaterThan 0
            expect( F.read fname ).toBe content
            expect( F.size fname ).toBe size

Ensure that trying to read the same file in a subfolder fails,
and that trying to read a file in a nonexistant folder fails.

            F.mkdir 'foo'
            F.cd 'foo'
            expect( -> F.read fname ).toThrowError 'No such file'
            expect( -> F.read 'what/ever/dude' ).toThrowError \
                'No such file'

Ensure that similar errors occur when attempting to do invalid
write operations.

            expect( -> F.write '/foo', content ).toThrowError \
                'Cannot write to a folder'
            expect( -> F.write 'what/ever/dude', content ) \
                .toThrowError 'Invalid folder path'

Ensure that we can write to subfolders and get the content from
them as well, and that we can write arbitrary objects.

            F.cd()
            expect( F._cwd ).toBe '/'
            object = {
                key1 : [ 1, 2, 3]
                key2 : innerObject : 'string'
            }
            fname2 = '/foo/my.obj'
            size2 = F.write fname2, object
            expect( size ).toBeGreaterThan 0
            expect( F.read fname2 ).toEqual object
            expect( F.size fname2 ).toBe size2

And yet this has not messed up the other file.

            expect( F.read fname ).toBe content
            expect( F.size fname ).toBe size

Append some text to the original text file, and ensure it does
what it's supposed to do.

            sizeMore = F.append fname, ' and more!'
            expect( sizeMore ).toBeGreaterThan size
            expect( F.read fname ).toBe content + ' and more!'
            expect( F.size fname ).toBe sizeMore

Append some text to a non-existant file, and ensure it creates
the file as if `write` had been called instead.

            fname3 = '/some.file.txt'
            shortText = 'short text'
            size3 = F.append fname3, shortText
            expect( size3 ).toBeGreaterThan 0
            expect( F.read fname3 ).toBe shortText
            expect( F.size fname3 ).toBe size3

Try to append some text to a file containing an object, and ensure
that it won't permit us to do so.

            expect( -> F.append fname2, 'text' )
                .toThrowError 'Cannot append to a file unless it
                    contains a string'

Verify that the same errors we get from calls to `write` also show
up where they're supposed to in calls to `append`.  (Thus these
tests are just copied from above, but with `write` changed to
`append`.

            expect( -> F.append '/foo', content ).toThrowError \
                'Cannot append to a folder'
            expect( -> F.append 'what/ever/dude', content ) \
                .toThrowError 'Invalid folder path'

Verify that sizes of folders and/or nonexistant files are -1.

            expect( F.size 'what/ever/dude' ).toBe -1
            expect( F.size '/' ).toBe -1
            expect( F.size '/foo' ).toBe -1
            expect( F.size '/fooooo' ).toBe -1

## Distinguishing files from folders

This tests both the `type` function of the `FileSystem` class and
the `ls` function, which can list all entries, just files, or
just folders.

        it 'can tell files from folders', ->
            F = new window.FileSystem 'example'

The following code sets up a hierarchy of files and folders with
this structure.
 * Documents (a folder)
   * Work (a folder)
     * To-do list.txt (a file)
   * Home (a folder)
     * Movies to see.txt (a file)
 * Settings (a folder)
   * SomeApp.xml (a file)
   * OtherApp.xml (a file)


            F.mkdir 'Documents/Work'
            F.mkdir 'Documents/Home'
            F.mkdir 'Settings'
            F.write 'Documents/Work/To-do list.txt',
                'Buy bread\n
                 Buy milk\n'
            F.write 'Documents/Home/Movies to see.txt',
                'Monty Python and the Holy Grail\n
                 One Flew Over the Cuckoo\'s Nest'
            F.write 'Settings/SomeApp.xml',
                '<settings><example>blah blah</example></settings>'
            F.write 'Settings/OtherApp.xml',
                '<settings><key>Foo</key>
                    <value>ON</value></settings>'

Now we ask what the type of each entry in the filesystem is.
Files should have type `'file'` and folders should have type
`'folder'`.

            expect( F.type '' ).toBe 'folder'
            expect( F.type '/' ).toBe 'folder'
            expect( F.type 'Documents' ).toBe 'folder'
            expect( F.type 'Documents/Work' ).toBe 'folder'
            expect( F.type 'Documents/Home' ).toBe 'folder'
            expect( F.type 'Settings' ).toBe 'folder'
            expect( F.type 'Documents/Work/To-do list.txt' )
                .toBe 'file'
            expect( F.type 'Documents/Home/Movies to see.txt' )
                .toBe 'file'
            expect( F.type 'Settings/SomeApp.xml' ).toBe 'file'
            expect( F.type 'Settings/OtherApp.xml' ).toBe 'file'

Next, we ask the type of some entries that don't exist in the
filesystem, and expect to receive the answer "null" in each case.

            expect( F.type 'thing' ).toBeNull()
            expect( F.type 'Document' ).toBeNull()
            expect( F.type 'Documents/Wor' ).toBeNull()
            expect( F.type 'Settings/SomeApp' ).toBeNull()
            expect( F.type 'Documents/Work/Home' ).toBeNull()

Finally, we call `ls` on each folder in the filesystem, with each
of its possible arguments (including an invalid one).  But before
doing so, we add one file to the Documents folder, so that there
are a mix of both files and folders in it, for a more thorough
test.

            expect( F.write 'Documents/a-file.txt', 'foo' ) \
                .toBeGreaterThan 0

Now proceed with the tests of `ls`.

            # /
            F.cd '/'
            expect( F.ls() ).toEqual [ 'Documents', 'Settings' ]
            expect( F.ls 'all' ).toEqual \
                [ 'Documents', 'Settings' ]
            expect( F.ls 'files' ).toEqual [ ]
            expect( F.ls 'folders' ).toEqual \
                [ 'Documents', 'Settings' ]
            # /Documents
            F.cd 'Documents'
            expect( F.ls() ).toEqual \
                [ 'Home', 'Work', 'a-file.txt' ]
            expect( F.ls 'all' ).toEqual \
                [ 'Home', 'Work', 'a-file.txt' ]
            expect( F.ls 'files' ).toEqual [ 'a-file.txt' ]
            expect( F.ls 'folders' ).toEqual [ 'Home', 'Work' ]
            # /Documents/Work
            F.cd 'Work'
            expect( F.ls() ).toEqual [ 'To-do list.txt' ]
            expect( F.ls 'all' ).toEqual [ 'To-do list.txt' ]
            expect( F.ls 'files' ).toEqual [ 'To-do list.txt' ]
            expect( F.ls 'folders' ).toEqual [ ]
            # /Documents/Home
            F.cd '../Home'
            expect( F.ls() ).toEqual [ 'Movies to see.txt' ]
            expect( F.ls 'all' ).toEqual [ 'Movies to see.txt' ]
            expect( F.ls 'files' ).toEqual [ 'Movies to see.txt' ]
            expect( F.ls 'folders' ).toEqual [ ]
            # /Settings
            F.cd '../../Settings'
            expect( F.ls() ).toEqual \
                [ 'OtherApp.xml', 'SomeApp.xml' ]
            expect( F.ls 'all' ).toEqual \
                [ 'OtherApp.xml', 'SomeApp.xml' ]
            expect( F.ls 'files' ).toEqual \
                [ 'OtherApp.xml', 'SomeApp.xml' ]
            expect( F.ls 'folders' ).toEqual [ ]

We also call `ls` in two invalid folders to verify that it gives
errors at those times.

            F._cwd = '/Doc'
            expect( -> F.ls() )
                .toThrowError 'Invalid current working directory'
            F._cwd = '/Documents/a-file.txt'
            expect( -> F.ls() )
                .toThrowError 'Invalid current working directory'

## Removing folders and files

This test covers the `rm` command, which can be used on both files
and folders.

        it 'can remove files and folders', ->
            F = new window.FileSystem 'example'

The following code sets up a hierarchy of files and folders with
the same structure as in the previous test.

            F.mkdir 'Documents/Work'
            F.mkdir 'Documents/Home'
            F.mkdir 'Settings'
            F.write 'Documents/Work/To-do list.txt',
                'Buy bread\n
                 Buy milk\n'
            F.write 'Documents/Home/Movies to see.txt',
                'Monty Python and the Holy Grail\n
                 One Flew Over the Cuckoo\'s Nest'
            F.write 'Settings/SomeApp.xml',
                '<settings><example>blah blah</example></settings>'
            F.write 'Settings/OtherApp.xml',
                '<settings><key>Foo</key>
                    <value>ON</value></settings>'

Verify that file #2 in the filesystem is Settings/SomeApp.xml, and
that its type is a file.  Then remove it.  And verify that its type
is now null, and that file #2 is no longer in the filesystem.

            expect( JSON.parse localStorage.getItem F._fileName 2 )
                .toEqual '<settings><example>blah
                          blah</example></settings>'
            expect( F.type 'Settings/SomeApp.xml' ).toBe 'file'
            expect( F.rm 'Settings/SomeApp.xml' ).toBeTruthy()
            expect( F.type 'Settings/SomeApp.xml' ).toBeNull()
            expect( localStorage.getItem F._fileName 2 ).toBeNull()

Repeat the previous exercise with the whole Documents folder.

            expect( JSON.parse localStorage.getItem F._fileName 0 )
                .toEqual 'Buy bread\n
                          Buy milk\n'
            expect( JSON.parse localStorage.getItem F._fileName 1 )
                .toEqual 'Monty Python and the Holy Grail\n
                          One Flew Over the Cuckoo\'s Nest'
            expect( F.type 'Documents/Work' ).toBe 'folder'
            expect( F.type 'Documents/Work/To-do list.txt' )
                .toBe 'file'
            expect( F.type 'Documents/Home' ).toBe 'folder'
            expect( F.type 'Documents/Home/Movies to see.txt' )
                .toBe 'file'
            expect( F.rm 'Documents' ).toBeTruthy()
            expect( localStorage.getItem F._fileName 0 ).toBeNull()
            expect( localStorage.getItem F._fileName 1 ).toBeNull()
            expect( F.type 'Documents/Work' ).toBeNull()
            expect( F.type 'Documents/Work/To-do list.txt' )
                .toBeNull()
            expect( F.type 'Documents/Home' ).toBeNull()
            expect( F.type 'Documents/Home/Movies to see.txt' )
                .toBeNull()

And yet, the final of the files remains, untouched by all of this.

            expect( JSON.parse localStorage.getItem F._fileName 3 )
                .toEqual '<settings><key>Foo</key>
                          <value>ON</value></settings>'

An interesting question then arises:  Will adding a new file
(correctly) give it index zero?  It ought to, so let us verify
that fact.

            expect( F.write '/check.txt', '10% gratuity' )
                .toBeGreaterThan 0
            expect( JSON.parse localStorage.getItem F._fileName 0 )
                .toEqual '10% gratuity'
            expect( JSON.parse localStorage.getItem F._fileName 3 )
                .toEqual '<settings><key>Foo</key>
                          <value>ON</value></settings>'

## Copying files

To perform this test, we only need one folder and two files, in the
following arrangement.
 * file1.txt
 * /folder
   * file2.txt


        it 'can copy files correctly', ->
            F = new window.FileSystem 'example'
            F.write 'file1.txt', 'Some text content'
            F.mkdir 'folder'
            F.write 'folder/file2.txt', 'This is also text'
            expect( F.size 'file1.txt' ).toBeGreaterThan 0
            expect( F.size 'folder/file2.txt' ).toBeGreaterThan 0

First, we copy file1.txt to another name in the same (root) folder.

            expect( F.cp 'file1.txt', 'cp.txt' ).toBeTruthy()
            expect( F.read 'cp.txt' ).toBe 'Some text content'

Next, we copy it into the folder and verify that that works as well.

            expect( F.cp 'file1.txt', 'folder' ).toBeTruthy()
            expect( F.read 'folder/file1.txt' ).toBe \
                'Some text content'

Repeat the previous test, this time specifying a specific filename.

            expect( F.cp 'file1.txt', 'folder/a.txt' ).toBeTruthy()
            expect( F.read 'folder/a.txt' ).toBe 'Some text content'

Now try overwriting an existing file and be sure that it fails.

            expect( F.cp 'file1.txt', 'folder/file2.txt' ) \
                .toBeFalsy()
            expect( F.read 'folder/file2.txt' ).toBe \
                'This is also text'

Repeat the previous test but this time letting it infer the filename
when only given a folder as the destination.  (Begin by writing new
content into folder/file1.txt, for comparison purposes.)

            expect( F.write 'folder/file1.txt', 'New content' ) \
                .toBeTruthy()
            expect( F.cp 'file1.txt', 'folder' ).toBeFalsy()
            expect( F.read 'folder/file1.txt' ).toBe 'New content'
