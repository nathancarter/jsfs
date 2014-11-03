
# jsfs

*A (small) filesystem stored in the browser's LocalStorage*

![Travis-CI build status](https://travis-ci.org/nathancarter/jsfs.svg?branch=master)

## Introduction

If you're writing a client-side app, you may want to give the user a
virtual filesystem in which to store the data they create in the app.
Users are accustomed to files and folders, so this provides them.

Note that this project does not provide any UI; it is exclusively the
backend.  Present lists of files and folders to your user in whatever
UI your project already uses.

The goal is to have this tool work in any browser, which is why
it uses LocalStorage.  (IndexedDB [does not work in Mobile Safari](
http://caniuse.com/#feat=indexeddb) and [is not actually persistent
in Chrome](https://developers.google.com/chrome/whitepapers/storage#persistent).)
Thus we create a filesystem in LocalStorage, which has a maximum size
of 5MB (or 2.5MB, depending on the browser).  So far I've only run the test suite in desktop Chrome.

If you're looking for something that can handle more than 5MB, you
should try [filer.js](https://github.com/ebidel/filer.js/) instead,
but it is based on IndexedDB, with the limitations listed above.

## How to use it

Download [the JavaScript code](release/jsfs.js) or
[the minified version](release/jsfs.min.js) and import them into your
page the usual way.

```html
<script type="text/javascript" src="jsfs.min.js"></script>
```

Create a filesystem object with whatever name you like.  You can have
multiple (completely separate) filesystems under different names, in
case you have multiple apps on your site.  (LocalStorage is
shared across a domain.)

```javascript
var F = new window.FileSystem( "The user's documents" );
```

Read and write any JSON-serializable objects into the filesystem you
like.

```javascript
F.write( "tps_report.txt", reportObject );
// ... later ...
var reloaded = F.read( "tps_report.txt" );
```

## The API

You can create and navigate a hierarchy of folders with the
functions listed below.  They are links to the source code, which
is written in a literate language, so it's documentation, too.
 * [cd](jsfs.litcoffee#cd)
 * [ls](jsfs.litcoffee#ls)
 * [read](jsfs.litcoffee#read)
 * [write](jsfs.litcoffee#write)
 * [append](jsfs.litcoffee#append)
 * [size](jsfs.litcoffee#size)
 * [type](jsfs.litcoffee#type)
 * [mv](jsfs.litcoffee#mv)
 * [cp](jsfs.litcoffee#cp)
 * [rm](jsfs.litcoffee#rm)
 * [mkdir](jsfs.litcoffee#mkdir)
 * [constructor](jsfs.litcoffee#constructor)

You can turn on and off data compression with an optional third parameter to
the `write` and `append` functions, or just set a default for all write
operations with `F.compressionDefault = true` (or `false`).

## The future

I'd like to add a GUI demo to make this more tangible, and to ease its
integration into projects for which the demo would be directly re-usable.
Details appear in [the to-do list](TODO.md).

## Contributing

```
$ git clone https://github.com/nathancarter/jsfs.git
$ cd jsfs
$ npm install
$ ./node_modules/.bin/cake all
```

If you'd like to contribute, [please let me
know](https://github.com/nathancarter) so that we can talk about the
changes first.  I'm glad to accept pull requests, of course.  Note
that they will need to come with corresponding additions to the unit
tests, which appear here.
 * [tests/index.html](tests/index.html)
 * [tests/class-spec.litcoffee](tests/class-spec.litcoffee)
 * [tests/instance-spec.litcoffee](tests/instance-spec.litcoffee)

If you plan to extend the API in any way, be sure to update this
README as well, so that there are links into the appropriate
portions of the source code, documenting your new functions.

## License

[LGPL3](LICENSE)
