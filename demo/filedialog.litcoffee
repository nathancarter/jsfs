
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

It's also important to be able to programmatically click buttons.  The
default way this works is that the call is passed along to the `tellPage`
function in `filedialog.html`, which, in turn, sends it to the containing
page via inter-frame message passing.  If you re-use this demo UI in an
actual application, this behavior can be overridden at either level; you can
assign a new handler over this function, or over `tellPage`, whichever you
prefer.

    window.buttonClicked = ( name ) ->

The only button we handle internally is the "New folder" button.  All others
are passed on to the page.

        if name is 'New folder'
            folderName = prompt 'Enter name of new folder', 'My Folder'
            if fsToBrowse.mkdir folderName
                updateFileBrowser()
            else
                alert 'That folder name is already in use.'
            return

When passing the "Save" button, also pass the currently-chosen filename
under which to save.

        args = [ ]
        if name is 'Save' then args.push saveFileName.value
        tellPage [ 'buttonClicked', name ].concat args

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

We will track the set of features that need to be enabled or disabled,
depending on the mode in which the dialog is operating.  This defaults to
the settings required for "manage files" mode.

        features =
            navigateFolders : yes
            deleteFolders : yes
            deleteFiles : yes
            createFolders : yes
            fileNameTextBox : no

We also set up other defaults, for title bar and status bar content.

        title = fileBrowserMode[0].toUpperCase() + fileBrowserMode[1..]
        buttons = [ ]

Now we update the above default options based on the current mode.  If the
mode has somehow been set to an invalid value, the defaults will hold.

        if fileBrowserMode is 'manage files'
            buttons = [ 'New folder', 'Done' ]
        else if fileBrowserMode is 'save file'
            features.deleteFolders = features.deleteFiles = no
            features.fileNameTextBox = yes
            buttons = [ 'New folder', 'Save' ]

We will store in the following array the set of entries that will show up in
the center of the dialog, in a two-column tables.

        entries = [ ]

We add to that array all the folders in the cwd.  These are links if and
only if `navigateFolders` was enabled in the features set.

First, the link to the parent folder, if and only if we're not at the
filesystem root.

        if fsToBrowse.getCwd() isnt FileSystem::pathSeparator
            I = icon 'up-arrow'
            T = 'Parent folder'
            if features.navigateFolders
                action = -> fsToBrowse.cd '..' ; updateFileBrowser()
                I = makeActionLink I, action
                T = makeActionLink T, action
            entries.push rowOf3 I, T

Next, the links to all other folders in the cwd.  These are just like the
parent folder, except they can also be deleted, if and only if the
`deleteFolders` feature is enabled in the features set.

        for folder in fsToBrowse.ls( '.', 'folders' )
            I = icon 'folder'
            T = folder
            if features.navigateFolders
                do ( folder ) ->
                    action = -> fsToBrowse.cd folder ; updateFileBrowser()
                    I = makeActionLink I, action
                    T = makeActionLink T, action
            X = ''
            if features.deleteFolders
                do ( folder ) ->
                    X = makeActionLink icon( 'delete' ), ->
                        askToDeleteEntry folder
            entries.push rowOf3 I, T, X

After the folders in the cwd, we also list all the files in the cwd.  These
cannot be navigated, but they can be deleted if and only if the
`deleteFiles` feature is nabled in the features set.

        for file in fsToBrowse.ls '.', 'files'
            I = icon 'text-file'
            T = file
            if features.fileNameTextBox
                do ( file ) ->
                    action = -> saveFileName.value = file
                    I = makeActionLink I, action
                    T = makeActionLink T, action
            X = ''
            if features.deleteFiles
                do ( file ) ->
                    X = makeActionLink icon( 'delete' ), ->
                        askToDeleteEntry file
            entries.push rowOf3 I, T, X

Now create the interior of the dialog using the `makeTable` function,
defined below.  If the entries list is empty, then we must be at the root
and there are no files or folders, so in that unusual case, include a
message indicating that the entire filesystem is empty.

        if entries.length is 0 then entries.push '(empty filesystem)'
        interior = makeTable entries

If this is a "save" dialog, we need a text box into which to type the
filename under which we wish to save.  We add it to the status bar, but if
we are not in dialog-imitation mode, that will automatically get moved into
the content proper.

        titlebar = statusbar = ''
        if features.fileNameTextBox
            statusbar = "File name:
                         <input id='saveFileName' type='text' width=40/>"

The interior of the dialog is created.  We will add to it a title bar and a
status bar if and only if we have been asked to do so.  The following code
checks to see if we are supposed to imitate a dialog box, and if so, creates
the necessary HTML to do so.

        if imitateDialog
            path = fsToBrowse.getCwd()
            buttons = ( "<input type='button' value='#{text}'
                          onclick='buttonClicked(\"#{text}\");'>" \
                        for text in buttons ).join ' '
            if path is FileSystem::pathSeparator then path += ' (top level)'
            titlebar = "<table border=1 cellpadding=5 cellspacing=0
                               width=100% height=100%>
                          <tr height=1%>
                            <td bgcolor=#cccccc>
                              <table border=0 cellpadding=0 cellspacing=0
                                     width=100%>
                                <tr>
                                  <td align=left width=33%>
                                    <b>#{title}</b>
                                  </td>
                                  <td align=center width=34%>
                                    Folder: #{path}
                                  </td>
                                  <td align=right width=33%>
                                    #{icon 'close'}
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                          <tr>
                            <td bgcolor=#fafafa valign=top>"
            statusbar = "   </td>
                          </tr>
                          <tr height=1%>
                            <td bgcolor=#cccccc>
                              <table border=0 cellpadding=0 cellspacing=0
                                     width=100%>
                                <tr>
                                  <td align=left width=50%>
                                    #{statusbar}
                                  </td>
                                  <td align=right width=50%>
                                    #{buttons}
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                        </table>"

Place the final result in the document.  If there is a "save file" text box,
preserve its contents across changes to the DOM.

        oldName = saveFileName?.value
        document.body.innerHTML = titlebar + interior + statusbar
        if oldName and saveFileName then saveFileName.value = oldName

The following utility function makes a two-column table out of the string
array given as input.  This is useful for populating the file dialog.

    makeTable = ( entries ) ->
        result = '<table border=0 width=100% cellspacing=5 cellpadding=5>'
        half = Math.ceil entries.length/2
        for i in [0...half]
            left = entries[i]
            right = entries[i+half]
            result += "<tr>
                         <td width=50% bgcolor=#e8e8e8>#{left}</td>
                         <td width=50%
                           #{if right then 'bgcolor=#e8e8e8' else ''}>
                           #{right or ''}
                         </td>
                       </tr>"
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
        "<table border=0 cellpadding=0 cellspacing=0 width=100%><tr>
         <td width=22>#{icon or ''}</td>
         <td align=left>#{text} &nbsp; &nbsp; </td>
         <td align=left width=66><nobr>#{more}</nobr></td></tr></table>"
