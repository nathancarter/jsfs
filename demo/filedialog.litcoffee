
This file is used by `filedialog.html` in the same folder, to provide a demo
GUI for browsing a `jsfs` filesystem.

# State variables

The following variables determine the state of this page.

## Name of FileSystem to browse

This dialog can browse any filesystem stored in LocalStorage.  It defaults
to browsing the one created in the demo page [index.html](index.html).

    fsToBrowse = new FileSystem 'demo'

When setting the name of the filesystem to browse, an entirely new
`FileSystem` object is created.  The old one is discarded.

    window.setFileSystemName = ( name ) ->
        fsToBrowse = new FileSystem name
        updateFileBrowser()

## Browser mode

It can be in one of several modes, stored in a global variable, here.

    fileBrowserMode = null

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
    window.setFileBrowserMode = ( mode ) ->
        fileBrowserMode = mode if mode in validBrowserModes
        updateFileBrowser()

## Dialog imitation

It can imitate a dialog box by adding a status bar and title bar; whether to
do so is stored in a global variable, here.

    imitateDialog = no

Whether to imitate a dialog can only be true or false, so we use `!!` to
coerce things to a boolean.

    window.setDialogImitation = ( enable = yes ) ->
        imitateDialog = !!enable
        updateFileBrowser()

# Setup

When the demo GUI page loads, the following setup routine must get called.
For now, it is just a stub.

    window.onload = setup = ->
        setFileBrowserMode 'manage files'

# Update

Every time the view needs to be updated, the update routine defined below
will do so.  It will recompute the HTML content of the document body and
write it.

The update routine is as follows.

    updateFileBrowser = ->

Constants we'll want to use below.

        UP = '<img src="up-arrow.png" style="vertical-align: -20%;">'
        FI = '<img src="text-file.png" style="vertical-align: -20%;">'
        FO = '<img src="folder.png" style="vertical-align: -20%;">'

First we handle the case when the mode is "manage files."

        if fileBrowserMode is 'manage files'
            entries = [ ]
            if fsToBrowse.getCwd() isnt FileSystem::pathSeparator
                entries.push makeActionLink "#{UP} Parent folder", ->
                    fsToBrowse.cd '..'
                    updateFileBrowser()
            for folder in fsToBrowse.ls( '.', 'folders' )
                entries.push makeActionLink "#{FO} #{folder}",
                    do ( folder ) -> ->
                        fsToBrowse.cd folder
                        updateFileBrowser()
            for file in fsToBrowse.ls '.', 'files'
                entries.push "#{FI} #{file}"
            document.body.innerHTML = makeTable entries
            return

Now we have a fallback in the case when we haven't yet implemented the
visuals to handle the mode correctly.  This just prints that the
implementation is yet to come.

        document.body.innerHTML = "
            <p>(This implementation is only just beginning!  It is not at
                all complete!)<p>
            <p>File Browser Mode: #{fileBrowserMode}<p>
            <p>FileSystem Name: #{fsToBrowse.getName()}<p>
            <p>Imitate Dialog? #{imitateDialog}<p>
            "

The following utility function makes a two-column table out of the string
array given as input.  This is useful for populating the file dialog.

    makeTable = ( entries ) ->
        result = '<table border=0 width=100%>'
        half = Math.ceil entries.length/2
        for i in [0...half]
            result += "<tr><td width=50%>#{entries[i]}</td>
                           <td width=50%>#{entries[i+half] or ''}</td></tr>"
        result + '</table>'

The following utility function makes a link that calls a script function.

    window.actionLinks = [ ]
    clearActionLinks = -> actionLinks = [ ]
    makeActionLink = ( text, func ) ->
        number = actionLinks.length
        actionLinks.push func
        "<a href='javascript:void(0);'
            onclick='actionLinks[#{number}]();'>#{text}</a>"
