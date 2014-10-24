
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

        _changeFileSystem : ( changeFunction ) ->
            fs = @_getFilesystemObject()
            backup = JSON.stringify fs
            try
                changeFunction fs
                localStorage.setItem @_storageName(),
                    JSON.stringify fs
            catch e
                @_cache[@_name] = JSON.parse backup
                throw e

## Changing directories

There will be several situations in which we need to deal with
path strings.  The first is here, where we have functions for
changing the cwd, and they accept a path as argument, and need to
parse it.  For this reason, we need tools for splitting and
joining paths at path separators (and thus using escape
characters to escape path separators in file and folder names).
Here they are.

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
            ( simultaneousReplace pathString, \
                esc+sep, sep, esc+esc, esc, sep, '\n' ).split '\n'
        _joinPath : ( pathArray ) ->
            sep = FileSystem::pathSeparator
            esc = FileSystem::escapeCharacter
            ( simultaneousReplace p, sep, esc+sep, esc, esc+esc \
                for p in pathArray ).join sep

(Cwd functions not yet implemented...to come...)

## More to come

There is much more to implement!  This class is not close to done.
See [the to-do list for this project](TODO.md).

