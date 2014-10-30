
# To-do list for this project

## Supporting multiple tabs

The current architecture for [the `FileSystem` class](jsfs.litcoffee)
permits creation of multiple `FileSystem` objects with the same name, but
all must be within the same JavaScript environment (i.e., the same tab).
This is supported by caching, at the class level, of the filesystem object
loaded from LocalStorage, and sharing it across all instances.

The problem with this is that the user could easily open multiple tabs in
their browser, using the same app in each, and the cached filesystem objects
would get out of date, because changes in one tab would not impact the
filesystem object cached in another tab.

Consequently, the architecture for caching filesystem objects needs to be
removed.  This will be a small decrease in efficiency, but is important for
the reasons given above.  Furthermore, this will mean removing the
`_changeFilesystem` function and rewriting any code that uses it.

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
