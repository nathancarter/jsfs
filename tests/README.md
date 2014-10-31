
# Test folder

The files in this folder are specs that use
[Jasmine](http://jasmine.github.io/), which is located in the
[jasmine-2.0.3](jasmine-2.0.3) subfolder.

The file [class-spec.litcoffee](class-spec.litcoffee) tests aspects of the
`FileSystem` class that are implemented at the class level, not for
instances.  E.g., variables in the `FileSystem` namespace, methods that
require no instance, etc.

The file [instance-spec.litcoffee](instance-spec.litcoffee) tests methods
that can only be run on instances of the `FileSystem` class.  E.g.,
creating, modifying, and reading filesystems and their files.  Naturally,
most of the testing takes place in that file.

To see the results of these tests, simply open [index.html](index.html) in
your browser.  As of this writing, you cannot do that online, but must clone
the repository and do it from your own working copy.  Eventually I may copy
`master` over into `gh-pages` so that you can see the tests passing online,
but I have not yet seen the need to do so.
