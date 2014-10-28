
# jsfs

### Tiny JavaScript filesystem stored in LocalStorage

## Introduction

If you're writing a client-side app, you want to give the user a
virtual filesystem in which to store the data they create in the app.
Users are accustomed to files and folders, so this provides them.

The goal here is to have this tool work in any browser, which is why
it uses LocalStorage.  (IndexedDB [does not work in Mobile Safari](
http://caniuse.com/#feat=indexeddb) and [is not actually persistent
in Chrome](https://developers.google.com/chrome/whitepapers/storage#persistent).)
Thus we create a filesystem in LocalStorage, which has a maximum size
of 5MB (or 2.5MB, depending on the browser).

If you're looking for something that can handle a lot of files, you
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

You can create and navigate a hierarchy of folders in the usual way,
with functions `cd`, `ls`, `mkdir`, `rm`, `mv`, `cp`, and query the
size and types of files with `size` and `type`.  At the moment, the
only documentation for these things is [in the source
code](jsfs.litcoffee), which is at least written in a literate style,
so it's easy to read.

## The future

I'd like to add data compression so that even LocalStorage can hold
more than just 5MB (uncompressed).  Details appear in [the to-do
list](TODO.md).
