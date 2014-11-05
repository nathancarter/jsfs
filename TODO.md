
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

 * Implement the update routine for "Open folder" mode.  It's the same as
   "Open file" mode, but with the following differences.
   * The Open button will be called "Open this folder."
   * The "Open this folder" button will always be enabled.
   * Do not use a drop-down control for file type filtering.
   * Show files grayed out.
   * Do not let files be selected.
   * The callback when "Open this folder" is clicked will pass the cwd.
