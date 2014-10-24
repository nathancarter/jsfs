
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

Because the name is read-only, we provide the following getter
for it.

        getName : -> @_name

## Making changes

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

## More to come

There is much more to implement!  This class is not close to done.
See [the to-do list for this project](TODO.md).

