
# One build task to rule them all

The following build task builds everything, which at this point
includes just the jsfs library and the test specs.  See below for
what each of those individual tasks means.

    taskQueue = []
    next = -> if taskQueue.length then invoke taskQueue.shift()
    task 'all', 'All the tasks listed below', ->
        taskQueue.push 'build'
        taskQueue.push 'test'
        next()

Also, the following utility function is handy for executing a
sequence of shell commands, and ensuring each succeeds before
proceeding on to the next.  It will be used in some tasks below.

Provide it data as a list of object, each with these attributes.
 * `command :` required attribute, string, shell command to run
 * `cwd :` optional attribute, defaults to `'.'`, current working
   directory in which to run the command
 * `description :` optional attribute, defaults to `command`, the
   text that will be printed to the console when the command is
   started


    colors = require 'colors'
    { exec } = require 'child_process'
    runShellCommands = ( commandData, callback = -> ) ->
        if commandData.length is 0 then return callback()
        nextCommand = commandData.shift()
        if not nextCommand.command
            throw Error 'Missing command field in command datum'
        console.log nextCommand.description or nextCommand.command
        exec nextCommand.command, { cwd : nextCommand.cwd or '.' },
        ( err, stdout, stderr ) ->
            if stdout + stderr
                console.log stdout + stderr.red
            throw err if err
            runShellCommands commandData, callback

# The main build process

A Cakefile should define the tasks it can perform.  This one can
perform just one task, "build."  This compiles all the sources
(in literate coffeescript) into JavaScript, and minifies it, with
source maps, ready for production use.

    task 'build', 'Compile jsfs.litcoffee into release/', ->

## Ensure requirements present

In order to build this project, the `node.js` modules listed in
`packages.json` must be installed.  The following code verifies
that they are, and tells the user how to install them if they are
not.

        fs = require 'fs'
        pj = JSON.parse fs.readFileSync 'package.json'
        missing = ( key for key of pj.dependencies when \
            not fs.existsSync "./node_modules/#{key}" ).join ', '
        if missing isnt ''
            console.log "This folder is not yet set up.
                Missing node.js packages: #{missing}\n
                To fix this, run: npm install"
            process.exit 1

## Compile the one source file

This project is built from one source file, `jsfs.litcoffee`.
The main step of the build process is to compile that file into
JavaScript and minify it (with source maps).  We do so now.

We utilize the `runShellCommands` utility here to run a sequence
of shell commands in the current directory.  We compile the
`.litcoffee` source and minify it (creating source maps in both
steps) and then move the files into the `release/` folder.

        runShellCommands [
            {
                description : 'Compiling jsfs.litcoffee...'
                command : './node_modules/.bin/coffee
                           --map --compile jsfs.litcoffee'
            }
            {
                description : 'Minifying jsfs.js...'
                command : './node_modules/.bin/uglifyjs
                           -c -m -v false --in-source-map jsfs.js.map
                           -o jsfs.min.js --source-map
                           jsfs.min.js.map'
            }
            {
                description : 'Moving files to release/...'
                command : 'mv jsfs.js jsfs.js.map jsfs.min.js
                           jsfs.min.js.map release/'
            }
        ], ->
            console.log 'Done compiling and minifying
                source into release folder.'.green
            next()

# Testing

The following task compiles the test specs from literate
CoffeeScript files into JavaScript files, so that the unit testing
page (in `tests/index.html`) is up-to-date.

    task 'test', 'Compile tests/*.litcoffee test specs', ->
        colors = require 'colors'
        fs = require 'fs'
        html = ( fs.readFileSync 'tests/index.html' ).toString()

First find the list of files to build, and iterate over it, running
the CoffeeScript compiler on each.

        toBuild = ( file for file in fs.readdirSync 'tests' when \
            file[-10..] is '.litcoffee' )
        count = 0
        for file in toBuild
            do ( file ) ->
                runShellCommands [
                    {
                        description : "Compiling tests/#{file}..."
                        command : "./node_modules/.bin/coffee
                                   --compile #{file}"
                        cwd : 'tests'
                    }
                ], ->
                    file = file[..-11] + '.js'
                    console.log "Done building tests/#{file}."

Also check to see if the file we just compiled is mentioned in the
unit testing HTML file.  If not, issue a warning that there is a
compiled test spec that's unused.

                    if -1 is html.indexOf file
                        console.log "Warning: Compiled file
                            #{file} is not mentioned in
                            tests/index.html!".red

When the final parallel build of test specs completes, announce
successful completion.

                    if ++count is toBuild.length
                        console.log 'All test specs built.  Open
                            tests/index.html to run them and see
                            the results.'.green
                        next()
