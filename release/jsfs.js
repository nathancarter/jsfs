// Generated by CoffeeScript 1.7.1
(function() {
  var __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.FileSystem = (function() {
    var simultaneousReplace;

    _Class.prototype.pathSeparator = '/';

    _Class.prototype.escapeCharacter = '\\';

    _Class.prototype._cache = {};

    _Class.prototype._storageName = function() {
      return "" + this._name + "_filesystem";
    };

    _Class.prototype._fileName = function(number) {
      return "" + this._name + "_file_" + number;
    };

    _Class.prototype._getFilesystemObject = function() {
      var fs;
      if (FileSystem.prototype._cache.hasOwnProperty(this._name)) {
        return FileSystem.prototype._cache[this._name];
      }
      fs = localStorage.getItem(this._storageName());
      if (fs === null) {
        localStorage.setItem(this._name, JSON.stringify(fs = {}));
      }
      return FileSystem.prototype._cache[this._name] = fs;
    };

    function _Class(name) {
      this._name = ("" + name) || 'undefined';
      this._getFilesystemObject();
      this._cwd = FileSystem.prototype.pathSeparator;
    }

    _Class.prototype.getName = function() {
      return this._name;
    };

    _Class.prototype.getCwd = function() {
      return this._cwd;
    };

    _Class.prototype._changeFilesystem = function(changeFunction) {
      var backup, e, fs;
      fs = this._getFilesystemObject();
      backup = JSON.stringify(fs);
      try {
        changeFunction(fs);
        return localStorage.setItem(this._storageName(), JSON.stringify(fs));
      } catch (_error) {
        e = _error;
        this._cache[this._name] = JSON.parse(backup);
        throw e;
      }
    };

    simultaneousReplace = function() {
      var found, i, result, string, swaps, _i, _ref;
      string = arguments[0], swaps = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      result = '';
      while (string.length > 0) {
        found = false;
        for (i = _i = 0, _ref = swaps.length - 1; _i < _ref; i = _i += 2) {
          if (string.slice(0, swaps[i].length) === swaps[i]) {
            result += swaps[i + 1];
            string = string.slice(swaps[i].length);
            found = true;
            break;
          }
        }
        if (!found) {
          result += string[0];
          string = string.slice(1);
        }
      }
      return result;
    };

    _Class.prototype._splitPath = function(pathString) {
      var bit, esc, pos, sep, _i, _len, _ref, _results;
      sep = FileSystem.prototype.pathSeparator;
      esc = FileSystem.prototype.escapeCharacter;
      pos = pathString.indexOf(sep + sep);
      while (pos > -1) {
        pathString = pathString.slice(0, pos) + pathString.slice(pos + sep.length);
        pos = pathString.indexOf(sep + sep);
      }
      if (pathString.slice(0, sep.length) === sep) {
        pathString = pathString.slice(sep.length);
      }
      if (pathString.slice(-sep.length) === sep) {
        pathString = pathString.slice(0, -sep.length);
      }
      _ref = (simultaneousReplace(pathString, esc + sep, sep, esc + esc, esc, sep, '\n')).split('\n');
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        bit = _ref[_i];
        if (bit !== '') {
          _results.push(bit);
        }
      }
      return _results;
    };

    _Class.prototype._joinPath = function(pathArray) {
      var esc, p, sep;
      sep = FileSystem.prototype.pathSeparator;
      esc = FileSystem.prototype.escapeCharacter;
      return ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = pathArray.length; _i < _len; _i++) {
          p = pathArray[_i];
          _results.push(simultaneousReplace(p, sep, esc + sep, esc, esc + esc));
        }
        return _results;
      })()).join(sep);
    };

    _Class.prototype._toAbsolutePath = function(cwdPath, relativePath) {
      var result, sep;
      sep = FileSystem.prototype.pathSeparator;
      if (relativePath.slice(0, sep.length) === sep) {
        return relativePath;
      }
      result = FileSystem.prototype._joinPath((FileSystem.prototype._splitPath(cwdPath)).concat(FileSystem.prototype._splitPath(relativePath)));
      if (result.slice(0, sep.length) !== sep) {
        result = sep + result;
      }
      return result;
    };

    _Class.prototype._toCanonicalPath = function(absolutePath) {
      var result, sep, step, _i, _len, _ref;
      result = [];
      _ref = FileSystem.prototype._splitPath(absolutePath);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        step = _ref[_i];
        if (step === '.') {
          continue;
        }
        if (step === '..') {
          if (result.length > 0) {
            result.pop();
          }
        } else {
          result.push(step);
        }
      }
      result = FileSystem.prototype._joinPath(result);
      sep = FileSystem.prototype.pathSeparator;
      if (result.slice(0, sep.length) !== sep) {
        result = sep + result;
      }
      return result;
    };

    _Class.prototype._isValidCanonicalPath = function(absolutePath) {
      var path, step, walk, _i, _len;
      path = FileSystem.prototype._splitPath(absolutePath);
      walk = this._getFilesystemObject();
      for (_i = 0, _len = path.length; _i < _len; _i++) {
        step = path[_i];
        walk = walk[step];
        if (!walk || walk instanceof Array) {
          return false;
        }
      }
      return true;
    };

    _Class.prototype.cd = function(path) {
      var newcwd;
      if (path == null) {
        path = FileSystem.prototype.pathSeparator;
      }
      newcwd = FileSystem.prototype._toCanonicalPath(FileSystem.prototype._toAbsolutePath(this._cwd, path));
      if (this._isValidCanonicalPath(newcwd)) {
        return this._cwd = newcwd;
      }
    };

    _Class.prototype.mkdir = function(path) {
      var e, hadToAdd, newpath;
      if (path == null) {
        path = '.';
      }
      newpath = FileSystem.prototype._splitPath(FileSystem.prototype._toCanonicalPath(FileSystem.prototype._toAbsolutePath(this._cwd, path)));
      try {
        hadToAdd = false;
        this._changeFilesystem(function(fs) {
          var step, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = newpath.length; _i < _len; _i++) {
            step = newpath[_i];
            if (!fs.hasOwnProperty(step)) {
              fs[step] = {};
              hadToAdd = true;
            }
            _results.push(fs = fs[step]);
          }
          return _results;
        });
        return hadToAdd;
      } catch (_error) {
        e = _error;
        return false;
      }
    };

    _Class.prototype._nextAvailableFileNumber = function() {
      var i, used, usedNumbers, _i, _ref;
      usedNumbers = (function(_this) {
        return function(fs) {
          var key, result, value;
          if (fs == null) {
            fs = _this._getFilesystemObject();
          }
          result = [];
          for (key in fs) {
            if (!__hasProp.call(fs, key)) continue;
            value = fs[key];
            if (value instanceof Array) {
              result.push(value[0]);
            } else {
              result.concat(usedNumbers(value));
            }
          }
          return result;
        };
      })(this);
      used = usedNumbers().sort(function(a, b) {
        return a - b;
      });
      if (used.length === 0) {
        return 0;
      }
      for (i = _i = 0, _ref = used[used.length - 1] + 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (__indexOf.call(used, i) < 0) {
          return i;
        }
      }
    };

    _Class.prototype.write = function(filename, content) {
      var e, fullpath, name, wrote;
      fullpath = FileSystem.prototype._splitPath(FileSystem.prototype._toCanonicalPath(FileSystem.prototype._toAbsolutePath(this._cwd, filename)));
      name = fullpath[fullpath.length - 1];
      wrote = false;
      try {
        this._changeFilesystem((function(_this) {
          return function(fs) {
            var data, number, step, _i, _len, _ref;
            _ref = fullpath.slice(0, -1);
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              step = _ref[_i];
              if (!fs.hasOwnProperty(step || fs[step] instanceof Array)) {
                throw Error('Invalid folder path');
              }
              fs = fs[step];
            }
            if (fs.hasOwnProperty(name)) {
              if (!(fs[name] instanceof Array)) {
                throw Error('Cannot write to a folder');
              }
              number = fs[name][0];
            } else {
              number = _this._nextAvailableFileNumber();
            }
            data = JSON.stringify(content);
            localStorage.setItem(_this._fileName(number), data);
            wrote = {
              name: _this._fileName(number),
              size: data.length
            };
            return fs[name] = [number, data.length];
          };
        })(this));
        return wrote.size;
      } catch (_error) {
        e = _error;
        if (wrote) {
          localStorage.removeItem(wrote.name);
        }
        throw e;
      }
    };

    _Class.prototype.read = function(filename) {
      var fs, fullpath, name, step, _i, _len, _ref;
      fullpath = FileSystem.prototype._splitPath(FileSystem.prototype._toCanonicalPath(FileSystem.prototype._toAbsolutePath(this._cwd, filename)));
      name = fullpath[fullpath.length - 1];
      fs = this._getFilesystemObject();
      _ref = fullpath.slice(0, -1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        step = _ref[_i];
        if (!fs.hasOwnProperty(step || fs[step] instanceof Array)) {
          throw Error('Invalid folder path');
        }
        fs = fs[step];
      }
      if (!fs.hasOwnProperty(name || !(fs[name] instanceof Array))) {
        throw Error('No such file in that folder');
      }
      return JSON.parse(localStorage.getItem(this._fileName(fs[name][0])));
    };

    return _Class;

  })();

}).call(this);

//# sourceMappingURL=jsfs.map
