
This file is used by `filedialog.html` in the same folder, to provide a demo
GUI for browsing a `jsfs` filesystem.

# Communicating with the page

This web page is used inside an `<iframe>` of another page, and thus it uses
message-passing (`onmessage` an `postMessage` calls) to communicate with
that outer page.

We therefore create two functions to handle this task.  The first one
listens for messages from the outer page and handles them by turning them
into function calls.  This permits the outer page to call any
(already-defined) function in the inner page.  The message's data should be
an array mimicking the function signature.  E.g., to call `f(a,b,c)`, send
the array `['f',a,b,c]` to this page using `postMessage`.

    window.onmessage = ( e ) ->
        if e.data not instanceof Array
            return console.log 'Invalid message from page:', e.data
        fname = e.data.shift()
        if typeof window[fname] isnt 'function'
            return console.log 'Cannot call non-function:', fname
        window[fname].apply null, e.data

The second function that handles message-passing with the page is for
communication in the other direction.  To tell the page any data, simply
pass it to the `tellPage` routine, and it will be posted to the containing
window via `postMessage`.

    tellPage = ( message ) -> window.parent.postMessage message, '*'

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

## Moving a file

When moving a file, we store in this global variable the name, folder, and
absolute path of the file being moved.

    window.fileBeingMoved = { }

## Opening a file

When opening a file, one particular file will be selected before the user
clicks the "Open" button.  This global variable records the name of that
file.  Only the name is needed, not the path, since only files in the
current directory can be selected.

    window.fileToBeOpened = null
    window.selectFile = ( name ) ->
        window.fileToBeOpened = name
        tellPage [ 'selectedFile', name ]
        updateFileBrowser()

## Changing folders

Whenever the browser changes folders, several things must happen, so it is
convenient to collect them into one method.  First, the filesystem itself
must change its cwd.  Second, the page containing this browser must be
notified.  Finally, any selected file needs to be deselected, thus updating
the view.

    changeFolder = ( destination ) ->
        fsToBrowse.cd destination
        tellPage [ 'changedFolder', fsToBrowse.getCwd() ]
        selectFile null

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

All other buttons are handled externally, but some need special processing
before we pass to the page the information that a button was clicked.  We
store any additional information we'll be passing the page in the following
arguments list.

        args = [ ]

When passing the "Save" button, also pass the currently-chosen filename
under which to save.  But if a file is actually being moved, then send a
"move" signal instead of a "save" signal.  The file will be moved right now,
and the signal will indicate whether the move succeeded or failed.

        if name is 'Save'
            path = fsToBrowse.getCwd()
            if path[-1..] isnt FileSystem::pathSeparator
                path += FileSystem::pathSeparator
            args.push path + saveFileName.value
            if fileBeingMoved.name
                args.unshift fileBeingMoved.full
                if fileBeingMoved.copy
                    success = fsToBrowse.cp fileBeingMoved.full,
                        path + saveFileName.value
                    name = if success then 'Copied' else 'Copy failed'
                else
                    success = fsToBrowse.mv fileBeingMoved.full,
                        path + saveFileName.value
                    name = if success then 'Moved' else 'Move failed'

When passing the "Save here" button, also pass the current working
directory.

        if name is 'Save here' then args.push fsToBrowse.getCwd()

When passing the "Open" button, also pass the full path to the file to open.

        if name is 'Open'
            path = fsToBrowse.getCwd()
            if path[-1..] isnt FileSystem::pathSeparator
                path += FileSystem::pathSeparator
            args.push path + fileToBeOpened

When passing the "Open this folder" button, also pass the cwd.

        if name is 'Open this folder'
            args.push fsToBrowse.getCwd()
            name = 'Open folder'

Send signal now.  Also, any button that was clicked in the status bar
completes the job of this dialog, thus returning us to "manage files" mode,
if the dialog even remains open.  Thus we make that change now.

        tellPage [ 'buttonClicked', name ].concat args
        window.fileBeingMoved = { }
        selectFile null
        setFileBrowserMode 'manage files'

# Setup

When the demo GUI page loads, the following setup routine must get called.
It simply sets the default mode, which also populates the view, and notifies
the page of the initial cwd.

    window.onload = setup = ->
        setFileBrowserMode 'manage files'
        changeFolder '.'

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

    window.updateFileBrowser = ->

We will track the set of features that need to be enabled or disabled,
depending on the mode in which the dialog is operating.  This defaults to
the settings required for "manage files" mode.

        features =
            navigateFolders : yes
            deleteFolders : yes
            deleteFiles : yes
            createFolders : yes
            fileNameTextBox : no
            filesDisabled : no
            moveFiles : yes
            moveFolders : yes
            copyFiles : yes
            extensionFilter : no
            selectFile : no

We also set up other defaults, for title bar and status bar content.

        title = if fileBrowserMode then \
            fileBrowserMode[0].toUpperCase() + fileBrowserMode[1..] \
            else ''
        buttons = [ ]

Now we update the above default options based on the current mode.  If the
mode has somehow been set to an invalid value, the defaults will hold.

        if fileBrowserMode is 'manage files'
            buttons = [ 'New folder', 'Done' ]
        else if fileBrowserMode is 'save file'
            features.deleteFolders = features.deleteFiles =
                features.moveFiles = features.moveFolders =
                features.copyFiles = no
            features.fileNameTextBox = yes
            title = 'Save as...'
            buttons = [ 'Cancel', 'Save' ]
            if imitateDialog then buttons.unshift 'New folder'
        else if fileBrowserMode is 'save in folder'
            features.deleteFolders = features.deleteFiles =
                features.moveFiles = features.moveFolders =
                features.copyFiles = no
            features.filesDisabled = yes
            title = 'Save in...'
            buttons = [ 'New folder', 'Cancel', 'Save here' ]
        else if fileBrowserMode is 'open file'
            features.deleteFolders = features.deleteFiles =
                features.moveFiles = features.moveFolders =
                features.copyFiles = no
            features.extensionFilter = features.selectFile = yes
            buttons = [ 'Cancel', 'Open' ]
        else if fileBrowserMode is 'open folder'
            features.deleteFolders = features.deleteFiles =
                features.moveFiles = features.moveFolders =
                features.copyFiles = no
            features.filesDisabled = yes
            buttons = [ 'Cancel', 'Open this folder' ]

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
                action = -> changeFolder '..'
                I = makeActionLink I, 'Go up to parent folder', action
                T = makeActionLink T, 'Go up to parent folder', action
            entries.push rowOf3 I, T

Next, the links to all other folders in the cwd.  These are just like the
parent folder, except they can also be deleted or moved, if and only if the
`deleteFolders` or `moveFolders` feature is enabled in the features set.

        for folder in fsToBrowse.ls '.', 'folders'
            I = icon 'folder'
            T = folder
            if features.navigateFolders
                do ( folder ) ->
                    action = -> changeFolder folder
                    I = makeActionLink I, 'Enter folder ' + folder, action
                    T = makeActionLink T, 'Enter folder ' + folder, action
            X = ''
            if features.deleteFolders
                do ( folder ) ->
                    X += makeActionLink icon( 'delete' ),
                        'Delete folder ' + folder, ->
                            askToDeleteEntry folder
            if features.moveFolders
                do ( folder ) ->
                    X += makeActionLink icon( 'move' ),
                        'Move folder ' + folder, ->
                            window.fileBeingMoved = name : folder
                            fileBeingMoved.path = fsToBrowse.getCwd()
                            fileBeingMoved.full = fileBeingMoved.path
                            sep = FileSystem::pathSeparator
                            if fileBeingMoved.full[-1..] isnt sep
                                fileBeingMoved.full += sep
                            fileBeingMoved.full += folder
                            fileBeingMoved.copy = no
                            fileBrowserMode = 'save file'
                            updateFileBrowser()
            entries.push rowOf3 I, T, X

After the folders in the cwd, we also list all the files in the cwd.  These
cannot be navigated, but they can be deleted, moved, copied, or selected if
and only if the `deleteFiles`, `moveFiles`, `copyFiles`, or `selectFile`
feature is enabled in the features set.

Also, files can be filtered using a drop-down list of extensions.  Let's
find out if the user has picked an item from that list.

        filter = fileFilter?.options[fileFilter?.selectedIndex].value
        if filter is '*.*' then filter = null else filter = filter?[1..]

Now proceed to examine all the files.

        for file in fsToBrowse.ls '.', 'files'
            if filter and file[-filter.length..] isnt filter then continue
            I = icon 'text-file'
            T = file
            if features.filesDisabled
                T = "<font color='#888888'>#{T}</font>"
            else if features.selectFile
                do ( file ) ->
                    action = -> selectFile file
                    I = makeActionLink I, 'Open ' + file, action
                    T = makeActionLink T, 'Open ' + file, action
            if features.fileNameTextBox
                do ( file ) ->
                    action = ->
                        saveFileName.value = file
                        saveBoxKeyPressed()
                    I = makeActionLink I, 'Save as ' + file, action
                    T = makeActionLink T, 'Save as ' + file, action
            X = ''
            if features.deleteFiles
                do ( file ) ->
                    X += makeActionLink icon( 'delete' ),
                        'Delete file ' + file, ->
                            askToDeleteEntry file
            if features.moveFiles
                do ( file ) ->
                    X += makeActionLink icon( 'move' ),
                        'Move file ' + file, ->
                            window.fileBeingMoved = name : file
                            fileBeingMoved.path = fsToBrowse.getCwd()
                            fileBeingMoved.full = fileBeingMoved.path
                            sep = FileSystem::pathSeparator
                            if fileBeingMoved.full[-1..] isnt sep
                                fileBeingMoved.full += sep
                            fileBeingMoved.full += file
                            fileBeingMoved.copy = no
                            fileBrowserMode = 'save file'
                            updateFileBrowser()
            if features.copyFiles
                do ( file ) ->
                    X += makeActionLink icon( 'copy' ),
                        'Copy file ' + file, ->
                            window.fileBeingMoved = name : file
                            fileBeingMoved.path = fsToBrowse.getCwd()
                            fileBeingMoved.full = fileBeingMoved.path
                            sep = FileSystem::pathSeparator
                            if fileBeingMoved.full[-1..] isnt sep
                                fileBeingMoved.full += sep
                            fileBeingMoved.full += file
                            fileBeingMoved.copy = yes
                            fileBrowserMode = 'save file'
                            updateFileBrowser()
            entry = rowOf3 I, T, X
            if fileToBeOpened is file then entry = "SELECT#{entry}"
            entries.push entry

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
            statusbar += "File name:
                          <input id='saveFileName' type='text' size=40
                                 onkeyup='saveBoxKeyPressed(event);'/>"
        if features.extensionFilter
            extensions = ( "<option>#{e}</option>" \
                for e in allExtensions() )
            statusbar += "File type:
                          <select id='fileFilter'
                                  onchange='updateFileBrowser();'>
                            #{extensions.join '\n'}
                          </select>"

Construct the HTML for the buttons, which may be used in the status bar or
above it.

        for text, index in buttons
            disable = ''
            if text is 'Open' and not fileToBeOpened
                disable = 'disabled=true'
            buttons[index] = "<input type='button' value='  #{text}  '
                               id='statusBarButton#{text}' #{disable}
                               onclick='buttonClicked(\"#{text}\");'/>"
        buttons = buttons.join ' '

The interior of the dialog is created.  We will add to it a title bar and a
status bar if and only if we have been asked to do so.  The following code
checks to see if we are supposed to imitate a dialog box, and if so, creates
the necessary HTML to do so.

        if imitateDialog
            path = fsToBrowse.getCwd()
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

If we are not to create a title bar and status bar, then any status bar
content we've already created needs to be embedded in the document itself
instead.  In the special case where we are moving or copying a file, and
thus we need save/cancel buttons, and yet we are not in dialog imitation
mode, we move those buttons into the statusbar, so that they will be
embedded in the interior of the dialog.

        else
            if window.fileBeingMoved.name
                statusbar += " &nbsp; " + buttons
            statusbar = "<div style='position: absolute; bottom: 0;
                                     width: 90%; margin-bottom: 5px;'>
                           <center>#{statusbar}</center>
                         </div>"

Place the final result in the document.

If there is a "save file" text box, preserve its contents across changes to
the DOM.  Do the same for a "file type" drop-down list.

Also, there is a global variable that can be set to contain the name of the
file being moved, when a move operation is in process; if that is the case,
then use that as the save filename.

        oldName = saveFileName?.value or fileBeingMoved?.name
        oldIndex = fileFilter?.selectedIndex
        document.body.innerHTML = titlebar + interior + statusbar
        if oldName and saveFileName? then saveFileName.value = oldName
        if oldIndex and fileFilter? then fileFilter.selectedIndex = oldIndex
        saveBoxKeyPressed()
        if saveFileName? then saveFileName.focus()

The above function depends on a handler to enable/disable the Save button
based on whether the file name has been filled in.  The following function
is that handler.  It also simulates Save/Cancel button presses in response
to Enter/Escape key presses, respectively.

    window.saveBoxKeyPressed = ( event ) ->
        name = saveFileName?.value
        statusBarButtonSave?.disabled = !name
        if typeof name is 'string'
            tellPage [ 'saveFileNameChanged', name ]
        if event?.keyCode is 13 then return buttonClicked 'Save'
        if event?.keyCode is 27 then return buttonClicked 'Cancel'

The following utility function makes a two-column table out of the string
array given as input.  This is useful for populating the file dialog.

    makeTable = ( entries ) ->
        result = '<table border=0 width=100% cellspacing=5 cellpadding=5>'
        half = Math.ceil entries.length/2
        for i in [0...half]
            left = entries[i]
            lcolor = 'bgcolor=#e8e8e8'
            if left[...6] is 'SELECT'
                lcolor = 'bgcolor=#ddddff'
                left = left[6..]
            right = entries[i+half]
            rcolor = 'bgcolor=#e8e8e8'
            if not right then rcolor = ''
            else if right[...6] is 'SELECT'
                rcolor = 'bgcolor=#ddddff'
                right = right[6..]
            result += "<tr>
                         <td width=50% #{lcolor}>#{left}</td>
                         <td width=50% #{rcolor}>#{right or ''}</td>
                       </tr>"
        result + '</table>'

The following utility function makes a link that calls a script function.

    window.actionLinks = [ ]
    clearActionLinks = -> actionLinks = [ ]
    makeActionLink = ( text, tooltip, func ) ->
        number = actionLinks.length
        actionLinks.push func
        "<a href='javascript:void(0);' title='#{tooltip}'
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

The following utility function finds all extensions on all files in the
whole filesystem, and returns them in alphabetical order.  This is useful
for creating a drop-down list of extensions for filtering in the "open"
version of the dialog.

    allExtensions = ( F = null ) ->
        if not F then F = new FileSystem fsToBrowse.getName()
        result = [ '*.*' ]
        for file in F.ls '.', 'files'
            extension = /\.[^.]*?$/.exec file
            if extension
                extension = '*' + extension
                if extension not in result then result.push extension
        for folder in F.ls '.', 'folders'
            F.cd folder
            for extension in allExtensions F
                if extension not in result then result.push extension
            F.cd '..'
        result.sort()
