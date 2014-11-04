
This file is used by `filedialog.html` in the same folder, to provide a demo
GUI for browsing a `jsfs` filesystem.

# Setup

When the demo GUI page loads, the following setup routine must get called.
For now, it is just a stub.

    window.onload = setup = ->
        setFileBrowserMode 'manage files'

# Update

Every time the view needs to be updated, the update routine defined below
will do so.  It will recompute the HTML content of the document body and
write it.  First, however, we need some state variables that it will use.

It can be in one of several modes, stored in a global variable, here.

    fileBrowserMode = null

It can imitate a dialog box by adding a status bar and title bar; whether to
do so is stored in a global variable, here.

    imitateDialog = no

The update routine is as follows.

    updateFileBrowser = ->
        document.body.innerHTML = fileBrowserMode # temporary stub

# Setting state variables

## Browser mode

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

## Dialog imitation

Whether to imitate a dialog can only be true or false, so we use `!!` to
coerce things to a boolean.

    setDialogImitation = ( enable = yes ) ->
        imitateDialog = !!enable
        updateFileBrowser()
