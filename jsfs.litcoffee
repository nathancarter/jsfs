
# The FileSystem Class

This is the main object exposed by this library.  Instances of it
create/maintain new filesystems inside the browser's LocalStorage.

    window.FileSystem = class

## Global variables

This class uses the following path separator.  It can appear in file and
folder names, but will be escaped using the following escape character.

        pathSeparator : '/'
        escapeCharacter : '\\'

The following methods establish the naming convention we use in
LocalStorage.  The first is for storing the filesystem, and the second for
storing individual files.

        _storageName : -> "#{@_name}_filesystem"
        _fileName : ( number ) -> "#{@_name}_file_#{number}"

The next two methods read and write the filesystem object to and from
LocalStorage.  The second returns false if it failed, which would usually be
for storage space reasons.

        _getFilesystemObject : ->
            fs = JSON.parse localStorage.getItem @_storageName()
            if fs is null then @_setFilesystemObject fs = { }
            fs
        _setFilesystemObject : ( fs ) ->
            try
                localStorage.setItem @_storageName(), JSON.stringify fs
                yes
            catch e
                no

Now we create similar methods for reading and writing a file to storage,
based on its file data array, as stored in the filesystem.  (These are *not*
public APIs, which will be based on paths; these are internal APIs which
assume that the path has been traversed, and the array data for the file
found within the filesystem object.)

The read method returns the object serialized from the string read.  The
write method returns undefined on success and throws an error on failure.
On success, it modifies the size entry of the given file array.  It takes an
object as parameter and serializes it for you.

Both apply compression/decompression using
[lz-string](http://pieroxy.net/blog/pages/lz-string/index.html) if and only
if the `LZString` object is defined.  If it is not defined, but the file
array requires using it, an error is thrown.

        _readFile : ( farray ) ->
            result = localStorage.getItem @_fileName farray[0]
            if farray[2]
                if not LZString?
                    throw Error 'Cannot decompress file; LZString undefined'
                result = LZString.decompress result
            JSON.parse result
        _writeFile : ( farray, content ) ->
            data = JSON.stringify content
            if farray[2]
                if not LZString?
                    throw Error 'Cannot compress file; LZString undefined'
                data = LZString.compress data
            localStorage.setItem @_fileName( farray[0] ), data
            farray[1] = data.length

We also need a method for removing a file.

        _removeFile : ( farray ) ->
            localStorage.removeItem @_fileName farray[0]

## Constructor

The constructor allows you to pass a name, which will be used like a
namespace within the LocalStorage object, so that multiple filesystems could
exist all within the same LocalStorage without colliding.  The name should
be a nonempty string, but if not, it will be converted to one.

        constructor : ( name ) ->

The name is read-only, so we use the underscore convention to indicate that
it should be treated as private.

            @_name = "#{name}" || 'undefined'

The constructor then ensures that the corresponding filesystem object has
been loaded into the cache, or created there.

            @_getFilesystemObject()

The current working directory (cwd hereafter) is initialized to the root.

            @_cwd = FileSystem::pathSeparator # i.e., /

Whether or not to use compression defaults to false.  This way clients who
do not import the
[lz-string](http://pieroxy.net/blog/pages/lz-string/index.html) library will
not get errors.  This can be changed directly, since it does not use the
initial underscore to mark it as private.

            @compressionDefault = no

For read-only attributes, we provide getters here.

        getName : -> @_name
        getCwd : -> @_cwd

## Dealing with directories (internal API)

There will be several situations in which we need to deal with path strings.
For this reason, we need tools for splitting and joining paths at path
separators (and thus using escape characters to escape path separators in
file and folder names), and for converting relative paths to absolute paths,
absolute paths to canonical paths, and detecting what paths are valid ones.
Here are all of those tools.

This function is useful in path splitting and joining. `simultaneousReplace
s, a1, b1, ..., an, bn` returns `s` after the application of all the
simultaneous replacements "`a1` becomes `b1`," through "`an` becomes `bn`."
It is defined with ordinary assignment so that it is simply a local variable
to this class definition, not a class member.

        simultaneousReplace = ( string, swaps... ) ->
            result = ''
            while string.length > 0
                found = no
                for i in [0...swaps.length-1] by 2
                    if string[...swaps[i].length] is swaps[i]
                        result += swaps[i+1]
                        string = string[swaps[i].length..]
                        found = yes
                        break
                if not found
                    result += string[0]
                    string = string[1..]
            result

All the remaining functions in this section are members of the private API
for this class, so they all begin with an underscore.

Take a string such as "/usr/local/bin" and turn it into an array such as `[
'usr', 'local', 'bin' ]`.  This is careful to respect the path separator
declared earlier, and when it might be escaped by the escape character
declared earlier as well.

The one quirk of this function is that it yields the same result whether or
not the path begins with the path separator (i.e., is an absolute path).
I.e., "usr/local/bin" gives the same output as "/usr/local/bin".

        _splitPath : ( pathString ) ->
            sep = FileSystem::pathSeparator
            esc = FileSystem::escapeCharacter
            pos = pathString.indexOf sep+sep
            while pos > -1
                pathString = pathString[...pos] +
                    pathString[pos+sep.length..]
                pos = pathString.indexOf sep+sep
            if pathString[...sep.length] is sep
                pathString = pathString[sep.length..]
            if pathString[-sep.length..] is sep
                pathString = pathString[...-sep.length]
            ( bit for bit in ( simultaneousReplace pathString, \
                esc+sep, sep, esc+esc, esc, sep, '\n' ) \
                .split '\n' when bit isnt '' )

Inverse of the previous function.  This one always outputs a relative path.
So, for example, an input of `[ 'usr', 'local' ]` yields an output of
"usr/local".

        _joinPath : ( pathArray ) ->
            sep = FileSystem::pathSeparator
            esc = FileSystem::escapeCharacter
            ( simultaneousReplace p, sep, esc+sep, esc, esc+esc \
                for p in pathArray ).join sep

This function turns relative paths into absolute paths, if given a starting
(current) directory from which to begin walking.  The result is always an
absolute path.  No attempt is made to verify whether the path is valid in
any filesystem, nor is any attempt made to canonicalize the path (i.e.,
apply `.` or `..` entries).

If this function is given an absolute path as its second argument,
it returns it unchanged.

        _toAbsolutePath : ( cwdPath, relativePath ) ->
            sep = FileSystem::pathSeparator
            if relativePath[...sep.length] is sep then return relativePath
            result = FileSystem::_joinPath \
                ( FileSystem::_splitPath cwdPath ) \
                    .concat FileSystem::_splitPath relativePath
            if result[...sep.length] isnt sep then result = sep + result
            result

This function turns absolute, non-canonical paths (those that may contain
`.` and `..` entries) into absolute, canonical paths (those without such
entries).  Note that the input must be an absolute path to begin with;
otherwise the result is undefined. The result is always an absolute path.

        _toCanonicalPath : ( absolutePath ) ->
            result = [ ]
            for step in FileSystem::_splitPath absolutePath
                if step is '.' then continue
                if step is '..'
                    if result.length > 0 then result.pop()
                else
                    result.push step
            result = FileSystem::_joinPath result
            sep = FileSystem::pathSeparator
            if result[...sep.length] isnt sep then result = sep + result
            result

Finally, a function to test whether a path is valid in this filesystem.  A
path is valid if it is an absolute, canonical path that points to a file or
folder that actually exists in the filesystem.  This is the one function in
this section that must be run in an instance of this class; all the above
methods are class methods.

        _isValidCanonicalPath : ( absolutePath ) ->
            path = FileSystem::_splitPath absolutePath
            walk = @_getFilesystemObject()
            for step in path
                walk = walk[step]
                return no if not walk or walk instanceof Array
            yes

Combining all of the tools above yields a function that can take an absolute
or relative path and turn it into a canonical path, split into the array of
nested folders, and the filename separately.  This function does so,
returning an array of nested path names.  E.g., `F.separate 'a/b/../c'`
might return `[ 'a', 'c' ]`, if it were executed when the root of the
filesystem were the cwd.

        separate : ( path ) ->
            FileSystem::_splitPath FileSystem::_toCanonicalPath \
                FileSystem::_toAbsolutePath @_cwd, path

It is often desirable to have the results of the previous function split so
that the filename is separate from the rest of the path. (This holds true
even if the entry in question is not a file, but a folder.)  This function
does so, returning an object with two keys, `path` (the array of nested
folder names) and `name` (the name of the innermost entry, which may be a
file or a folder, or nothing if the path is invalid).

        separateWithFilename : ( path ) =>
            fullPath = @separate path
            path : fullPath[...-1], name : fullPath[fullPath.length-1]

When one has computed a sequence of nested path names, one of the first
things you want to do with it is use it to navigate into a filesystem
hierarchy.  The following function takes a node in the filesystem tree and
navigates downward from it along the sequence of steps in the given path
array.  It returns the deeper node on success, or null if any of the steps
in the chain was invalid.

        walkPath : ( start, pathArray ) ->
            for step in pathArray
                if not start.hasOwnProperty( step ) or
                   start[step] instanceof Array then return null
                start = start[step]
            start

The previous function assumes that the path is to a folder, and will thus
return null if a file is encountered.  The following version does the same
thing, up until the last step in the path, at which point it will accept
navigating to a file.

        walkPathAndFile : ( start, pathArray ) =>
            if pathArray.length is 0 then return start
            start = @walkPath start, pathArray[...-1]
            if not start then return null
            start[pathArray[pathArray.length-1]] or null

## Telling files from directories (public API)

The next two sections are about files and directories separately.

### type

This function allows you to tell files and folders apart.
JavaScript example:
 * `if ( F.type( 'foo/bar' ) == 'file' ) { ... }`

Asking for the type of the entry at a given path will return either the
string `'file'` if it is a file, the string `'folder'` if it is a folder, or
null if there is no such entry.

        type : ( pathToEntry ) =>

Find the entry to which the path points.  If at any point, we cannot follow
the path given, return null to indicate that there is no such entry.

            fullpath = @separate pathToEntry
            entry = @walkPathAndFile @_getFilesystemObject(), fullpath
            if not entry then return null

If it's an array, then it's data about where to find a file in the
LocalStorage.  Otherwise, it's a folder object.

            if entry instanceof Array then 'file' else 'folder'

## Working with directories (public API)

The functions in this section apply the internal API defined above to create
the public API clients expect for dealing with folders.  For dealing with
files, see further below.

### cd

First, the function for changing the cwd.
JavaScript examples:
 * `F.cd( '/' )`
 * `F.cd( '../../thing/' )`

This simply applies the function defined above for converting relative paths
to absolute ones, if needed, or just copies the absolute path over if not.
In either case, the path is then made canonical.

        cd : ( path = FileSystem::pathSeparator ) ->
            newcwd = FileSystem::_toCanonicalPath \
                FileSystem::_toAbsolutePath @_cwd, path
            @_cwd = newcwd if @_isValidCanonicalPath newcwd

### mkdir

The following member function creates a new directory.
JavaScript examples:
 * `F.mkdir( 'newfoldername' )`
 * `F.mkdir( 'series/of/nested/folders' )`

It takes as input an absolute or relative path and creates all necessary
folders en route to the one named.  It returns true on success or false on
failure.  It only fails if there was not enough space to store the new
filesystem, or if the folder already exists.

        mkdir : ( path = '.' ) ->
            walk = fs = @_getFilesystemObject()
            addedSomething = no
            for step in @separate path
                if not walk.hasOwnProperty step
                    walk[step] = { }
                    addedSomething = yes
                walk = walk[step]
            addedSomething and @_setFilesystemObject fs

### ls

The following member function lists all entries in a given folder.
Examples:
 * `F.ls()` (current working directory, as goverened by `cd`, above)
 * `F.ls( '..', 'files' )` (return only files, not folders)
 * `F.ls( '/', 'folders' )` (return only folders, not files)

The first parameter defaults to the current folder, so `F.ls()` behaves just
like the `ls` command on \*nix systems. The second parameter says what type
of entries to list, `'files'`, `'folders'`, or `'all'` (the default).

        ls : ( folder = '.', type = 'all' ) ->

First split the given folder into steps.

            fullpath = @separate folder

Now find the folder to which the cwd points.

            folder = @walkPath @_getFilesystemObject(), fullpath
            if not folder then throw Error 'Invalid folder'

Now `folder` is the folder whose contents we need to list.  Return the
entries, filtered if need be.

            if type is 'all' or type is 'files'
                files = ( entry for own entry of folder when \
                    folder[entry] instanceof Array )
                files.sort()
                if type is 'files' then return files
            folders = ( entry for own entry of folder when \
                folder[entry] not instanceof Array )
            folders.sort()
            if type is 'all' then folders.concat files else folders

Thus the return value will be undefined if an invalid parameter was passed.

## Dealing with files (internal API)

Files are numbered starting at zero, so we need a way to find the next
available number, at which we can store a new file.  The following function
accomplishes this.

        _nextAvailableFileNumber : ->
            keys = [ ]
            keys.push localStorage.key i for i in [0...localStorage.length]
            result = [ ]
            usedNumbers = ( fs = @_getFilesystemObject() ) =>
                for own key, value of fs
                    if value instanceof Array
                        result.push value[0]
                    else
                        result = result.concat usedNumbers value
                result
            used = usedNumbers().sort ( a, b ) -> a - b
            if used.length is 0 then return 0
            for i in [0..used[used.length-1]+1]
                if i not in used then return i

## Working with files (public API)

The functions in this section apply the internal API defined in the previous
section to create the public API clients expect for dealing with files.  For
dealing with folders, see earlier.

### write

First, a function for writing a file to storage.
JavaScript examples:
 * `F.write( 'myfile.txt', 'some string content' )`
 * `F.write( 'folder/file.dat', myJavaScriptObject )`

Note that an optional third parameter says whether or not to compress the
data.  The corresponding `read` function knows whether or not the data was
compressed on write, and is smart enough to apply decompression if and only
if needed.  Naturally, compressed files are smaller, but it takes longer to
write them, since the compression algorithm must be applied.  For small
files, this difference should be negligible.
 * `F.write( 'myfile.zip', 'some string content', true );`

The default for writing is uncompressed, but you can change that default by
setting `F.compressionDefault = true;`.  In that case, you can write
uncompressed files by passing `false` as the optional third argument.

The file content can be any JavaScript object to which `JSON.stringify` can
be applied.

        write : ( filename, content, compress = @compressionDefault ) ->

First split the path into steps and lift the last one off as the filename.

            { path, name } = @separateWithFilename filename

Walk down the given path to find the folder in which the file should be
created.

            fs = @_getFilesystemObject()
            folder = @walkPath fs, path
            if not folder then throw Error 'Invalid folder path'

Find the index of the file to which we should write, or create a new index
if there is none. And read the old contents of the file, if any, in case
later writing fails and we must undo this.

            if folder.hasOwnProperty name
                if folder[name] not instanceof Array
                    throw Error 'Cannot write to a folder'
                file = folder[name]
                former = @_readFile file
            else
                file = [ @_nextAvailableFileNumber(), 0 ]
                former = null

Write the new contents to the file and store the new file size in the
filesystem.  Remember whether it was compressed, in case we need to undo,
below.

            wasCompressed = file[2]
            file[2] = compress
            @_writeFile file, content
            folder[name] = file

Try to save the new filesystem into LocalStorage.  If this fails, put the
file back the way it was and return a false value to indicate failure.

            if not @_setFilesystemObject fs
                file[2] = wasCompressed
                if former
                    @_writeFile file, former
                else
                    @_removeFile file
                return no

Everything succeeded, so return the size of the new file.

            file[1]

### read

Second, the corresponding function to read the data from a file into which
we previously wrote it.
JavaScript example:
 * `var restoredObject = F.read( 'file.out' )` (no need to do any
   `JSON.parse` yourself)

This function simply wraps the internal API for reading a file based on its
number with some tools that turn a filename into a file number, by looking
it up in the filesystem object.

        read : ( filename ) ->
            file = @walkPathAndFile @_getFilesystemObject(),
                @separate filename
            if not file then throw Error 'No such file'
            @_readFile file

### size

A very similar function to `read` is `size`, which just returns the size of
the file rather than reading the content.
JavaScript example:
 * `var N = F.size( 'maybe-a-big-file.xml' );`

Because our filesystem records the size of each write in the filesystem
hierarchy object itself, we do not need to read the file's contents from
LocalStorage to answer the question.

        size : ( filename ) ->

Find the file.  The only difference here from the `read` function's code is
that rather than throw errors for invalid paths, we just return -1 as the
file size.

            file = @walkPathAndFile @_getFilesystemObject(),
                @separate filename

Return the file's size, which is stored in the second entry of its array, or
-1 if `file` is undefined.

            file?[1] or -1

### append

Finally, the append function is like a read and a write combined. It
requires that the content to append be a string, and the content of the file
also be a string.  If either of these is not so, an error will be thrown.
JavaScript example:
 * `F.append( 'logs/errors.log', 'An error occurred' );`

The optional third parameter to `append` is the same as that to `write`,
above.  [See there](#write) for more information.

Much of the code below is like that of `write`, above.  So the comments here
are less than they were above.

        append : ( filename, content, compress = @compressionDefault ) ->
            if typeof content isnt 'string'
                throw Error 'Can only append strings to a file'

First split the path into steps and lift the last one off as the filename.

            { path, name } = @separateWithFilename filename

Find the folder in which the file should be created.

            fs = @_getFilesystemObject()
            folder = @walkPath fs, path
            if not folder then throw Error 'Invalid folder path'

Find the index of the file to which we should write, or create a new index
if there is none.  When the file does exist, verify that its contents are a
string, and if so, glue them onto the content passed as parameter.

            if folder.hasOwnProperty name
                if folder[name] not instanceof Array
                    throw Error 'Cannot append to a folder'
                file = folder[name]
                former = @_readFile file
                if typeof former isnt 'string'
                    throw Error 'Cannot append to a file
                        unless it contains a string'
                content = former + content
            else
                file = [ @_nextAvailableFileNumber(), 0 ]
                former = null

Serialize and write it into LocalStorage, just as we did in `write`.

            wasCompressed = file[2]
            file[2] = compress
            @_writeFile file, content
            folder[name] = file

Try to save the new filesystem into LocalStorage.  If this fails, put the
file back the way it was and return a false value to indicate failure.

            if not @_setFilesystemObject fs
                file[2] = wasCompressed
                if former
                    @_writeFile file, former
                else
                    @_removeFile file
                return no

Everything succeeded, so return the size of the new file.

            file[1]

## Moving and removing files and folders

### rm

The `rm` function (for "remove") removes the entire filesystem subtree from
a given point on downwards.  The parameter passed must be an existing file
or folder in the filesystem, and it (and all its descendants, if any) will
be removed.
JavaScript examples:
 * `F.rm( 'fileToRemove.txt' )`
 * `F.rm( '/or/even/a/nested/folder' )` (removes recursively)

This returns true upon successful removal, or false if the path given as the
parameter does not point to a valid point in the filesystem hierarchy.

        rm : ( path ) =>

First, split compute the path array from the given input.

            { path, name } = @separateWithFilename path

Now, if they passed in the filesystem root as the folder to be deleted, we
return false.  We can't remove the whole filesystem with this method.

            if not name then return no

Now find the entry in the filesystem at that path.

            fs = @_getFilesystemObject()
            folder = @walkPath fs, path
            if not folder then return no
            if not folder.hasOwnProperty name then return no

Now we need a recursive routine to find all the files that exist in the
filesystem hierarchy, from this point on downwards.  The following local
function does the job.

            filesBeneath = ( entry ) ->

If the filesystem entry we're looking at *is* a file, then we return just
that one entry.

                if entry instanceof Array then return [ entry ]

Otherwise, recur on all its children and concatenate the results.

                result = [ ]
                for own child of entry
                    result = result.concat filesBeneath entry[child]
                result

So now we leverage that routine to get a list of all the files we need to
delete.

            @_removeFile file for file in filesBeneath folder[name]

Now that all the files have been deleted, we delete the folder in the
filesystem, and save the filesystem object, and return success.  (The only
thing that should make the save fail should be a lack of space, but this
routine deletes things, so all should go fine.)

            delete folder[name]
            @_setFilesystemObject fs
            yes

### cp

The following function copies a file to a new location in the filesystem.
Both parameters should be filenames, but if the destination filename is the
name of an existing folder, then the original file's name will be appended
to it.
JavaScript examples:
 * `F.cp( 'source/file.html', 'destination/newname.html' )`
 * `F.cp( 'source/file.html', 'newfolder' )` (will create file
   newfolder/file.html, assuming newfolder is indeed a folder)
 * `F.cp( 'copyThis.xml', 'toHere.xml' )` (in cwd)

This will fail if the destination folder does not exist, if the destination
file already exists, or if there is not enough storage space.  Otherwise it
will succeed.  Returns true on success, false on failure.

        cp : ( source, dest ) ->

Find the file whose data we should copy.  If there is no such file, return
failure.

            fs = @_getFilesystemObject()
            sourcePath = @separate source
            file = @walkPathAndFile fs, sourcePath
            if not file or file not instanceof Array then return no

Find the destination to which we should copy it.  This requires considering
that the destination might be given as the name of a not-yet-existing file,
or it might be given as an existing folder.  Both options are handled here.

            { path, name } = @separateWithFilename dest
            destFolder = @walkPath fs, path
            if not destFolder then return
            if not name then destName = sourceName
            else if destFolder.hasOwnProperty name
                if destFolder[name] instanceof Array then return
                destFolder = destFolder[name]
                name = sourcePath[sourcePath.length-1]
                if destFolder.hasOwnProperty name then return

So we now know we must copy the data in `file` to the new folder
`destFolder`, under the name `name`.  So first we read the data that we will
copy, and try to write it into a new file.  If that fails, there is not
enough space to do the copy, and we return false.

            data = @_readFile file
            newfile = [ @_nextAvailableFileNumber(), 0 ]
            try
                @_writeFile newfile, data
            catch e
                return no

Copying the file's data succeeded, so we try to update the filesystem
hierarchy to reflect the change.  If this fails, then we also revert the
file writing we just did, so that everything remains consistent.

            destFolder[name] = newfile
            if not @_setFilesystemObject fs
                @_removeFile newfile
                return no
            yes

### mv

The following function moves a file or folder to a new destination within
the filesystem.  The parameters behave just as in `cp`, above, but the
source can be an entire folder.
JavaScript examples:
 * `F.mv( 'source/file.html', 'destination/newname.html' )`
 * `F.mv( 'source/file.html', 'newfolder' )` (will create file
   newfolder/file.html, assuming newfolder is indeed a folder)
 * `F.mv( 'moveThis.xml', 'toHere.xml' )` (in cwd)

        mv : ( source, dest ) ->

Find the file or folder we should copy.

            fs = @_getFilesystemObject()
            { path, name } = @separateWithFilename source
            sourceFolder = @walkPath fs, path
            if not sourceFolder or not sourceFolder.hasOwnProperty name
                throw Error 'No such file or folder'
            sourceName = name

Find the destination to which we should copy it.  This requires considering
that the destination might be given as the name of a not-yet-existing file
or folder, or it might be given as an existing folder.  Both options are
handled here (also taking into account the possibility that the name may be
undefined if the path is the root).

            { path, name } = @separateWithFilename dest
            destFolder = @walkPath fs, path
            destName = name
            if not destFolder then return
            if not name then destName = sourceName
            else if destFolder.hasOwnProperty name
                if destFolder[destName] instanceof Array then return
                destFolder = destFolder[destName]
                destName = sourceName
                if destFolder.hasOwnProperty destName then return

So we now know we must move the object `sourceFolder[sourceName]` to sit
within `destFolder` instead.  No change to the actual files need be done;
this is only a move within the hierarchy.

            destFolder[destName] = sourceFolder[sourceName]
            delete sourceFolder[sourceName]
            @_setFilesystemObject fs

## More to come

The essentials of this project are complete, but I do aim to one day
extend this code with support for data compression.
See [the to-do list for this project](TODO.md).
