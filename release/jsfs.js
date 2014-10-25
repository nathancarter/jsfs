// Generated by CoffeeScript 1.7.1
(function() {
  var __slice = [].slice;

  window.FileSystem = (function() {
    var simultaneousReplace;

    _Class.prototype.pathSeparator = '/';

    _Class.prototype.escapeCharacter = '\\';

    _Class.prototype._cache = {};

    _Class.prototype._storageName = function() {
      return "" + this._name + "_filesystem";
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

    _Class.prototype._changeFileSystem = function(changeFunction) {
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

    return _Class;

  })();

}).call(this);

//# sourceMappingURL=jsfs.map
