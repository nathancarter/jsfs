
# To-do list for this project

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
