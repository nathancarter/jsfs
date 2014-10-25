
# The FileSystem Class

This is the main object exposed by this library.  Instances of it
create/maintain new filesystems inside the browser's LocalStorage.

    window.FileSystem = class

## Global variables

This class uses the following path separator.  It can appear in
file and folder names, but will be escaped using the following
escape character.

        pathSeparator : '/'
        escapeCharacter : '\\'

The class will keep a mapping from filesystem names to filesystem
objects, so that multiple instances of this class that point to
the same filesystem will not cause clashes with one another.

        _cache : { }

When a new instance is created, we will need to be able to add a
new item to the cache, or look it up if it's already in the
cache.  The following methods do so.  The first provides the
naming convention we use in LocalStorage.  The second reads
existing filesystems from LocalStorage when it can, and creates
and saves new ones otherwise.

        _storageName : -> "#{@_name}_filesystem"
        _fileName : ( number ) -> "#{@_name}_file_#{number}"
        _getFilesystemObject : ->
            if FileSystem::_cache.hasOwnProperty @_name
                return FileSystem::_cache[@_name]
            fs = localStorage.getItem @_storageName()
            if fs is null
                localStorage.setItem @_name,
                    JSON.stringify fs = { }
            FileSystem::_cache[@_name] = fs

## Constructor

The constructor allows you to pass a name, which will be used
like a namespace within the LocalStorage object, so that multiple
filesystems could exist all within the same LocalStorage without
colliding.  The name should be a nonempty string, but if not, it
will be converted to one.

        constructor : ( name ) ->

The name is read-only, so we use the underscore convention
to indicate that it should be treated as private.

            @_name = "#{name}" || 'undefined'

The constructor then ensures that the corresponding filesystem
object has been loaded into the cache, or created there.

            @_getFilesystemObject()

The current working directory (cwd hereafter) is initialized to
the root.

            @_cwd = FileSystem::pathSeparator # i.e., /

For read-only attributes, we provide getters here.

        getName : -> @_name
        getCwd : -> @_cwd

## Making changes (internal API)

When a change is made to the filesystem (not a file in it, but
the actual structure of the filesystem, such as moving a file
from one folder to another), that change must be written to
LocalStorage.  The potential problem is that such a write may
fail, and thus the change to the filesystem should also fail, and
the filesystem revert to its old state.

The following routine makes this possible.  It is an internal
routine that runs any function that changes the filesystem, but
wraps the execution as follows, for safety.  Before executing the
change, the current state of the filesystem is serialized for
backup.  If the change fails, the backup is restored before the
thrown error is permitted to propagate up the stack.

        _changeFilesystem : ( changeFunction ) ->
            fs = @_getFilesystemObject()
            backup = JSON.stringify fs
            try
                changeFunction fs
                localStorage.setItem @_storageName(),
                    JSON.stringify fs
            catch e
                @_cache[@_name] = JSON.parse backup
                throw e

## Dealing with directories (internal API)

There will be several situations in which we need to deal with
path strings.  For this reason, we need tools for splitting and
joining paths at path separators (and thus using escape
characters to escape path separators in file and folder names),
and for converting relative paths to absolute paths, absolute
paths to canonical paths, and detecting what paths are valid ones.
Here are all of those tools.

This function is useful in path splitting and joining.
`simultaneousReplace s, a1, b1, ..., an, bn` returns `s` after
the application of all the simultaneous replacements "`a1` becomes
`b1`," through "`an` becomes `bn`."  It is defined with ordinary
assignment so that it is simply a local variable to this class
definition, not a class member.

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

All the remaining functions in this section are members of the
private API for this class, so they all begin with an underscore.

Take a string such as "/usr/local/bin" and turn it into an array
such as `[ 'usr', 'local', 'bin' ]`.  This is careful to respect
the path separator declared earlier, and when it might be escaped
by the escape character declared earlier as well.

The one quirk of this function is that it yields the same result
whether or not the path begins with the path separator (i.e., is
an absolute path).  I.e., "usr/local/bin" gives the same output
as "/usr/local/bin".

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

Inverse of the previous function.  This one always outputs a
relative path.  So, for example, an input of `[ 'usr', 'local' ]`
yields an output of "usr/local".

        _joinPath : ( pathArray ) ->
            sep = FileSystem::pathSeparator
            esc = FileSystem::escapeCharacter
            ( simultaneousReplace p, sep, esc+sep, esc, esc+esc \
                for p in pathArray ).join sep

This function turns relative paths into absolute paths, if given
a starting (current) directory from which to begin walking.  The
result is always an absolute path.  No attempt is made to verify
whether the path is valid in any filesystem, nor is any attempt
made to canonicalize the path (i.e., apply `.` or `..` entries).

If this function is given an absolute path as its second argument,
it returns it unchanged.

        _toAbsolutePath : ( cwdPath, relativePath ) ->
            sep = FileSystem::pathSeparator
            if relativePath[...sep.length] is sep
                return relativePath
            result = FileSystem::_joinPath \
                ( FileSystem::_splitPath cwdPath ) \
                    .concat FileSystem::_splitPath relativePath
            if result[...sep.length] isnt sep
                result = sep + result
            result

This function turns absolute, non-canonical paths (those that may
contain `.` and `..` entries) into absolute, canonical paths
(those without such entries).  Note that the input must be an
absolute path to begin with; otherwise the result is undefined.
The result is always an absolute path.

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
            if result[...sep.length] isnt sep
                result = sep + result
            result

Finally, a function to test whether a path is valid in this
filesystem.  A path is valid if it is an absolute, canonical path
that points to a file or folder that actually exists in the
filesystem.  This is the one function in this section that must be
run in an instance of this class; all the above methods are class
methods.

        _isValidCanonicalPath : ( absolutePath ) ->
            path = FileSystem::_splitPath absolutePath
            walk = @_getFilesystemObject()
            for step in path
                walk = walk[step]
                return no if not walk or walk instanceof Array
            yes

## Working with directories (public API)

The functions in this section apply the internal API defined in
the previous section to create the public API clients expect for
dealing with folders.  For dealing with files, see further below.

First, the function for changing the cwd.  This simply applies the
function defined above for converting relative paths to absolute
ones, if needed, or just copies the absolute path over if not.
In either case, the path is then made canonical.

        cd : ( path = FileSystem::pathSeparator ) ->
            newcwd = FileSystem::_toCanonicalPath \
                FileSystem::_toAbsolutePath @_cwd, path
            @_cwd = newcwd if @_isValidCanonicalPath newcwd

The following member function creates a new directory.  It takes
as input an absolute or relative path and creates all necessary
folders en route to the one named.  It returns true on success or
false on failure.  It only fails if there was not enough space to
store the new filesystem, or if the folder already exists.

        mkdir : ( path = '.' ) ->
            newpath = FileSystem::_splitPath \
                FileSystem::_toCanonicalPath \
                FileSystem::_toAbsolutePath @_cwd, path
            try
                hadToAdd = no
                @_changeFilesystem ( fs ) ->
                    for step in newpath
                        if not fs.hasOwnProperty step
                            fs[step] = { }
                            hadToAdd = yes
                        fs = fs[step]
                hadToAdd
            catch e
                no

## Dealing with files (internal API)

Files are numbered starting at zero, so we need a way to find the
next available number, at which we can store a new file.  The
following function accomplishes this.

        _nextAvailableFileNumber : ->
            usedNumbers = ( fs = @_getFilesystemObject() ) =>
                result = [ ]
                for own key, value of fs
                    if value instanceof Array
                        result.push value[0]
                    else
                        result.concat usedNumbers value
                result
            used = usedNumbers().sort ( a, b ) -> a - b
            if used.length is 0 then return 0
            for i in [0..used[used.length-1]+1]
                if i not in used then return i

## Working with files (public API)

The functions in this section apply the internal API defined in
the previous section to create the public API clients expect for
dealing with files.  For dealing with folders, see earlier.

First, a function for writing a file to storage.  The file content
can be any JavaScript object to which `JSON.stringify` can be
applied.

        write : ( filename, content ) ->
            fullpath = FileSystem::_splitPath \
                FileSystem::_toCanonicalPath \
                FileSystem::_toAbsolutePath @_cwd, filename
            name = fullpath[fullpath.length-1]
            wrote = no
            try
                @_changeFilesystem ( fs ) =>
                    for step in fullpath[...-1]
                        if not fs.hasOwnProperty step or
                           fs[step] instanceof Array
                            throw Error 'Invalid folder path'
                        fs = fs[step]
                    if fs.hasOwnProperty name
                        if fs[name] not instanceof Array
                            throw Error 'Cannot write to a folder'
                        number = fs[name][0]
                    else
                        number = @_nextAvailableFileNumber()
                    data = JSON.stringify content
                    localStorage.setItem @_fileName( number ),
                        data
                    wrote =
                        name : @_fileName number
                        size : data.length
                    fs[name] = [ number, data.length ]
                wrote.size
            catch e
                if wrote then localStorage.removeItem wrote.name
                throw e

Second, the corresponding function to read the data from a file
into which we previously wrote it.  It is assumed that the string
in the file is the result of an application of `JSON.stringify`,
and thus `JSON.parse` is applied to it and the result returned.

        read : ( filename ) ->
            fullpath = FileSystem::_splitPath \
                FileSystem::_toCanonicalPath \
                FileSystem::_toAbsolutePath @_cwd, filename
            name = fullpath[fullpath.length-1]
            fs = @_getFilesystemObject()
            for step in fullpath[...-1]
                if not fs.hasOwnProperty step or
                   fs[step] instanceof Array
                    throw Error 'Invalid folder path'
                fs = fs[step]
            if not fs.hasOwnProperty name or
               fs[name] not instanceof Array
                throw Error 'No such file in that folder'
            JSON.parse localStorage.getItem @_fileName fs[name][0]

## More to come

There is much more to implement!  This class is not close to done.
See [the to-do list for this project](TODO.md).

