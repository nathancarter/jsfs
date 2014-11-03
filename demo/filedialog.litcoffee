
This file is used by `filedialog.html` in the same folder, to provide a demo
GUI for browsing a `jsfs` filesystem.

# Setup

When the demo GUI page loads, the following setup routine must get called.
For now, it is just a stub.

    window.onload = setup = ->
        undefined

# Update

Every time the view needs to be updated, the following routine will do so.
It will recompute the HTML content of the document body and write it.  It
can be in one of several modes, which we store in a global variable, here.

    fileBrowserMode = 'manage files'

The actual update routine is as follows.

    update = ->
        document.body.innerHTML = fileBrowserMode # temporary stub
