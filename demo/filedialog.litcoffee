
This file is used by `filedialog.html` in the same folder, to provide a demo
GUI for browsing a `jsfs` filesystem.

# Setup

When the demo GUI page loads, the following setup routine must get called.
For now, it is just a stub.

    window.onload = setup = ->
        setFileBrowserMode 'manage files'

# Update

Every time the view needs to be updated, the following routine will do so.
It will recompute the HTML content of the document body and write it.  It
can be in one of several modes, which we store in a global variable, here.

    fileBrowserMode = null

The update routine is as follows.

    updateFileBrowser = ->
        document.body.innerHTML = fileBrowserMode # temporary stub

Here are the valid modes, and a routine for changing the mode.  It
automatically calls the update function defined later for keeping the view
fresh.

    validBrowserModes = [
        'manage files'
        'open file'
        'save file'
        'open folder'
        'save in folder'
    ]
    setFileBrowserMode = ( mode ) ->
        fileBrowserMode = mode if mode in validBrowserModes
        updateFileBrowser()
