
# To-do list for this project

The project, as a back-end with no UI, is completely done and tested.  The
following tasks are only to create a demo UI to show the project off, and to
make the project easy to integrate into UI environments.  The goal is that
to use this project in an editor like
[TinyMCE](http://www.tinymce.com/wiki.php/Tutorials:Creating_custom_dialogs)
one could take most of the contents of this demo and import it directly into
their project, having only to install callbacks to hear the events they
want.

The plan is to create a webpage that demonstrates the software's features
with a simple file-browser UI in a single page.  This page should be
re-usable in other applications, such as inside a [TinyMCE
dialog](http://www.tinymce.com/wiki.php/Tutorials:Creating_custom_dialogs).
The specifics steps of the plan are below.

 * In `demo.litcoffee`, add all the following functionality.
   * A routine for setting whether the view should imitate a dialog by
     adding a title bar, buttons, etc. surrounding the table of files and
     folders.  This should end by calling the update routine.
   * A routine for setting the name of the filesystem that this UI should
     browse.  It defaults to the example name installed in the script tag
     in `index.html`.  This should end by calling the update routine.
     It should keep a variable of type `FileSystem` that is replaced with a
     new one each time this routine is called.
 * To the setup script tag in `index.html`, add a call to the routine that
   tells the browser to imitate a dialog.
 * Create text at the top of `index.html` that explains how this is a test.
 * Ensure there is a clear `<hr>` between it and the dialog being tested.
 * Add a drop-down that changes the mode of the dialog in the `<iframe>`.
 * Partially implement the update routine for "manage files" mode.  This
   should list a parent folder link (if cwd isn't the root), all folders in
   the cwd, and all files in the cwd, in that order, alphabetical within
   those three types, and with appropriate icons to their left.
 * Upgrade the folder names in that view to be links that change the cwd.
   This includes the virtual "parent folder" link.
 * Add X icons to the right of each file and (non-virtual) folder.  These
   should prompt for whether the file should be permanently deleted, and if
   the user says yes, remove the file.
 * When imitating a dialog in any mode, put the path in the title bar's
   center.
 * When imitating a dialog in "manage files" mode, use "Manage Files" as the
   title, and give a "Done" button in the statusbar.  That button should
   call a callback that can be customized from the outside.  In
   `index.html`, set the callback so that it just pops up an alert that
   says, "If this were a real dialog box, this button would close it."
   Implement the "Done" button in a button-click handler that can take the
   name of any button that might get added to the statusbar.  This way when
   this page is placed inside a dialog that provides buttons for it, the
   "Done" button can be programmatically called by the click handlers for
   those externally-created buttons.  Use this for all future buttons.
 * Implement the update routine for "save file" mode.  This should exclude
   the X icons next to the filename, and should make each file a link that
   places the file's name in a text box at the bottom of the file table
   (spanning both columns).
 * When imitating a dialog in "save file" mode, use "Save as..." as the
   title, and give "Save" and "Cancel" in the statusbar.
   * Save should call a callback and then return to "manage files" mode.
     In `index.html`, install a callback that just pops up an alert saying
     that the file would be saved under a certain name.
   * Cancel should do the same, but with a cancellation message instead,
     again through a callback installed by `index.html`.
 * Implement the update routine for "save in folder" mode.  This should show
   files only grayed out, unclickable.  They should have no X icons.  The
   Save button should change name to "Save here."
 * In "manage files" mode, add "Move" icons next to every file and folder.
   * This should switch to "Save as file/folder" mode (which mode depending
     on the type of the thing being moved) and store in an internal state
     variable the full path to the file to be moved.
   * Ensure that the buttons in `index.html` for changing modes of the demo
     dialog also clear out this internal state variable.  (You could do this
     by having all mode changes clear the variable, and then just ensure
     that internal mode changes set the state after doing the mode change.)
   * Update the dialog so that when "Save as file/folder" mode ends, if that
     internal state is non-null, then move is attempted.  Its success or
     failure is reported by a "move" callback, rather than a straight "save"
     callback.  There is no need for `index.html` to install a handler for
     it; a silent response is okay.
   * Ensure that the save modes do not show the move icons.
 * Repeat the previous task, but with "Copy" icons analogous to the "Move"
   icons.
 * Implement the update routine for "Open file" mode.
   * Files and folders should have no X/mv/cp icons.
   * Place a drop-down control as the last row of the table for filtering
     file types by extension.  Have as choices all extensions that appear
     in the entire filesystem.  Also always have `*.*` as a choice.
   * When the drop-down control changes, filter the files shown in the view.
   * If a file is clicked, it should become visibly selected, and any other
     previously-selected files become visibly deselected.
   * This should fire callbacks notifying of file selection, for use in
     enabling/disabling an Open button.  Similarly, navigating into a
     folder, which deselects all files, should fire a callback that no file
     is selected.
   * The statusbar should have Open and Cancel buttons.
   * The Open button should listen for the selection callback and only be
     enabled when a file is selected.
   * Cancel should fire a callback, and `index.html` should install one that
     just pops up an alert.
   * Open should fire a callback if and only if a file is selected.  (It
     should be disabled otherwise.)
   * Install from `index.html` a superficial callback function that pops up
     an alert with the file contents shown as JSON.
 * Implement the update routine for "Open folder" mode.  It's the same as
   "Open file" mode, but with the following differences.
   * The Open button will be called "Open this folder."
   * The "Open this folder" button will always be enabled.
   * Do not use a drop-down control for file type filtering.
   * Show files grayed out.
   * Do not let files be selected.
   * The callback when "Open this folder" is clicked will pass the cwd.
