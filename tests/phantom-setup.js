//
// Credit for this goes to Lorenzo Planas, who published it here:
// https://github.com/qindio/headless-jasmine-sample
// He released it under the MIT license.  Thanks, Lorenzo!
//

if (navigator.userAgent.indexOf("PhantomJS") > 0) {
    var consoleReporter = new jasmineRequire.ConsoleReporter()({
        showColors: true,
        timer: new jasmine.Timer,
        print: function() {
          console.log.apply(console, arguments)
        }
    });
    jasmine.getEnv().addReporter(consoleReporter);
}

