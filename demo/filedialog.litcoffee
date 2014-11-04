
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

# Editing utilities

The following function prompts the user, and if they agree, it deletes the
given file or folder permanently.  If they disagree, it does nothing.  If it
deletes the file or folder, then it updates the browser.

    askToDeleteEntry = ( entry ) ->
        if confirm "Are you sure you want to permantely delete #{entry}?"
            fsToBrowse.rm entry
            updateFileBrowser()

# Update

Every time the view needs to be updated, the update routine defined below
will do so.  It will recompute the HTML content of the document body and
write it.

The update routine is as follows.

    updateFileBrowser = ->

First we handle the case when the mode is "manage files."

        if fileBrowserMode is 'manage files'
            entries = [ ]
            if fsToBrowse.getCwd() isnt FileSystem::pathSeparator
                action = ->
                    fsToBrowse.cd '..'
                    updateFileBrowser()
                I = makeActionLink icon( 'up-arrow' ), action
                T = makeActionLink 'Parent folder', action
                entries.push rowOf3 I, T
            for folder in fsToBrowse.ls( '.', 'folders' )
                do ( folder ) ->
                    action = ->
                        fsToBrowse.cd folder
                        updateFileBrowser()
                    I = makeActionLink icon( 'folder' ), action
                    T = makeActionLink folder, action
                    X = makeActionLink icon( 'delete' ), ->
                        askToDeleteEntry folder
                    entries.push rowOf3 I, T, X
            for file in fsToBrowse.ls '.', 'files'
                entries.push rowOf3 icon( 'text-file' ), file,
                    makeActionLink icon( 'delete' ), ->
                        askToDeleteEntry file
            if entries.length is 0 then entries.push '(empty filesystem)'
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

The following utility function makes an icon from one in the demo folder.

    icon = ( name ) -> "<img src='#{name}.png'>"

The following utility function makes a three-part row, where the first part
is an icon (or empty), the second part is left-justified text, and the third
part is right-justified content (or empty).

    rowOf3 = ( icon, text, more = '' ) ->
        "<table border=0 cellpadding=0 cellspacing=0><tr>
         <td width=22>#{icon or ''}</td>
         <td align=left>#{text}</td>
         <td align=right>#{more}</td></tr></table>"
