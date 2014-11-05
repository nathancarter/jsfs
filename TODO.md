
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

 * Implement the move operation for folders as well.  (Files are done.)
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
