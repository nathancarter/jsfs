
# The build process

A Cakefile should define the tasks it can perform.  This one can
perform just one task, "build."  This compiles all the sources
(in literate coffeescript) into JavaScript, and minifies it, with
source maps, ready for production use.

    task 'build', 'Compile .litcoffee sources into .js files', ->

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

The first step is to call the CoffeeScript compiler.

        colors = require 'colors'
        { exec } = require 'child_process'
        console.log 'Compiling jsfs.litcoffee...'.green
        exec 'coffee --map --compile jsfs.litcoffee',
        { cwd : '.' }, ( err, stdout, stderr ) ->
            if stdout + stderr
                console.log ( stdout + stderr ).red
            throw err if err

The next step is to call UglifyJS.

            console.log 'Minifying jsfs.js...'.green
            exec './node_modules/uglify-js/bin/uglifyjs
                -c -m -v false --in-source-map jsfs.map
                -o jsfs.min.js --source-map jsfs.min.js.map',
            { cwd : '.' }, ( err, stdout, stderr ) ->
                if stdout + stderr
                    console.log ( stdout + stderr ).red
                throw err if err

Move the compiled files into the release folder.

                console.log 'Moving files to release/...'.green
                exec 'mv jsfs.js jsfs.map jsfs.min.js
                    jsfs.min.js.map release/',
                { cwd : '.' }, ( err, stdout, stderr ) ->
                    if stdout + stderr
                        console.log ( stdout + stderr ).red
                    throw err if err

That's the job!

                    console.log 'Done!'.green

# Testing

The following task compiles the test specs from literate
CoffeeScript files into JavaScript files, so that the unit testing
page (in `tests/index.html`) is up-to-date.

    task 'test', 'Compile .litcoffee test specs into .js files', ->
        colors = require 'colors'
        { exec } = require 'child_process'
        fs = require 'fs'
        html = ( fs.readFileSync 'tests/index.html' ).toString()

First find the list of files to build, and iterate over it, running
the CoffeeScript compiler on each.

        toBuild = ( file for file in fs.readdirSync 'tests' when \
            file[-10..] is '.litcoffee' )
        for file in toBuild
            console.log "Compiling tests/#{file}...".green
            exec "coffee --compile #{file}", { cwd : 'tests' },
            ( err, stdout, stderr ) ->
                if stdout + stderr
                    console.log ( stdout + stderr ).red
                throw err if err
                file = file[..-11] + '.js'
                console.log "Built tests/#{file}.".green

Also check to see if the file we just compiled is mentioned in the
unit testing HTML file.  If not, issue a warning that there is a
compiled test spec that's unused.

                if -1 is html.indexOf file
                    console.log "Warning: Compiled file #{file}
                        is not mentioned in tests/index.html!".red

