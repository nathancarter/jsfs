
# To-do list for this project

## Main work

For each step below, after implementing it, add a test as well.
In the bullet points below, `fs` refers to an example instance of
the class.  It will correspond to an object stored in
LocalStorage at `localStorage.NAME_filesystem` that will be a
hierarchy of objects, whose keys are the file or folder names,
and whose values are either another object (for folders) or a
two-element array (for files), of the form `[index,sizeInBytes]`.
For any given index $n$, the entry `localStorage.NAME_file_`$n$
will contain the file's contents, serialized and compressed.
 * `fs.rm filename` removes the given file or folder, returning
   true on success, or false if the path was invalid.  In the
   case of a folder, the removal is recursive.  All files are
   deleted permanently.
 * `fs.ls()` returns a map from names of entries in the cwd to
   strings, either `'file'` or `'folder'`.  If the cwd is
   invalid, it returns null.  If it is empty, `{}` instead.
 * `fs.ls 'files'` yields only the files, in alpha order.  Or an
   empty array if there are none.  Or null if cwd invalid.
 * `fs.ls 'folders'` yields only the folders, in alpha order.  Or
   an empty array if there are none.  Or null if cwd invalid.
 * `fs.size filename` yields the size in bytes of the file, if it
   exists, or -1 if it does not.  The filename can be an absolute
   or relative path.
 * `fs.read filename` yields the content of the file, as read
   from `localStorage`.  Run it through `JSON.parse`, so that
   arbitrary objects can be stored in files.  If there is no such
   file, null is returned.
 * `fs.write filename, content` overwrites the file (or creates a
   new one) storing the given content, which should be passed
   through `JSON.stringify` first.  Returns compressed data size
   on success, or throws an error on failure (e.g., invalid path,
   or storage full).
 * `fs.append filename, content` functions just as the previous,
   but concatenates strings, and thus requires that both the
   file's already existing content (if any) be a single string,
   and the new `content` must also be a string.
 * `fs.cp src, dest` attempts to copy a single file from the
   source path to the destination path.  Returns true on success
   or false on failure (out of storage space, or invalid
   destination path).  Does not work on folders, but that feature
   could be added later.
 * `fs.mv src, dest` functions just like cp, except it moves
   rather than copying.  This means that the entire operation can
   take place only in `localStorage.fileSystem`, without
   reference to the actual files themselves.

## Adding optional compression

 * Import something like
   [lz-string](http://pieroxy.net/blog/pages/lz-string/index.html)
   to do compression of JavaScript strings.
 * Add a third entry to each file in the filesystem object, a
   bool indicating whether the file is compressed or not.  There
   need be no public API for accessing it; it will only be used
   internally.
 * Ensure that `read` calls apply decompression if and only if
   the file has the compressed flag set to true.
 * Add an optional parameter to `write` and `append` calls,
   indicating whether they should compress the file.  It defaults
   to false.  Ensure that it updates the compression flag as
   well.
 * Add an option to the `FileSystem` class to allow for
   specifying the default behavior for `write` and `append`
   calls; the client can choose if it should default to
   compressed or uncompressed saves.

