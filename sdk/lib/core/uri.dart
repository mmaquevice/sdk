// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A parsed URI, as specified by RFC-3986, http://tools.ietf.org/html/rfc3986.
 */
class Uri {
  int _port;
  String _path;

  /**
   * Returns the scheme component.
   *
   * Returns the empty string if there is no scheme component.
   */
  final String scheme;

  /**
   * Returns the authority component.
   *
   * The authority is formatted from the [userInfo], [host] and [port]
   * parts.
   *
   * Returns the empty string if there is no authority component.
   */
  String get authority {
    if (!hasAuthority) return "";
    var sb = new StringBuffer();
    _writeAuthority(sb);
    return sb.toString();
  }

  /**
   * Returns the user info part of the authority component.
   *
   * Returns the empty string if there is no user info in the
   * authority component.
   */
  final String userInfo;

  /**
   * Returns the host part of the authority component.
   *
   * Returns the empty string if there is no authority component and
   * hence no host.
   */
  final String host;

  /**
   * Returns the port part of the authority component.
   *
   * Returns 0 if there is no port in the authority component.
   */
  int get port => _port;

  /**
   * Returns the path component.
   *
   * The returned path is encoded. To get direct access to the decoded
   * path use [pathSegments].
   *
   * Returns the empty string if there is no path component.
   */
  String get path => _path;

  /**
   * Returns the query component. The returned query is encoded. To get
   * direct access to the decoded query use [queryParameters].
   *
   * Returns the empty string if there is no query component.
   */
  final String query;

  /**
   * Returns the fragment identifier component.
   *
   * Returns the empty string if there is no fragment identifier
   * component.
   */
  final String fragment;

  /**
   * Cache the computed return value of [pathSegements].
   */
  List<String> _pathSegments;

  /**
   * Cache the computed return value of [queryParameters].
   */
  Map<String, String> _queryParameters;

  /**
   * Creates a new URI object by parsing a URI string.
   */
  static Uri parse(String uri) => new Uri._fromMatch(_splitRe.firstMatch(uri));

  Uri._fromMatch(Match m) :
    this(scheme: _emptyIfNull(m[_COMPONENT_SCHEME]),
         userInfo: _emptyIfNull(m[_COMPONENT_USER_INFO]),
         host: _eitherOf(
         m[_COMPONENT_HOST], m[_COMPONENT_HOST_IPV6]),
         port: _parseIntOrZero(m[_COMPONENT_PORT]),
         path: _emptyIfNull(m[_COMPONENT_PATH]),
         query: _emptyIfNull(m[_COMPONENT_QUERY_DATA]),
         fragment: _emptyIfNull(m[_COMPONENT_FRAGMENT]));

  /**
   * Creates a new URI from its components.
   *
   * Each component is set through a named argument. Any number of
   * components can be provided. The default value for the components
   * not provided is the empry string, except for [port] which has a
   * default value of 0. The [path] and [query] components can be set
   * using two different named arguments.
   *
   * The scheme component is set through [scheme]. The scheme is
   * normalized to all lowercase letters.
   *
   * The user info part of the authority component is set through
   * [userInfo].
   *
   * The host part of the authority component is set through
   * [host]. The host can either be a hostname, a IPv4 address or an
   * IPv6 address, contained in '[' and ']'. If the host contains a
   * ':' character, the '[' and ']' are added if not already provided.
   *
   * The port part of the authority component is set through
   * [port]. The port is normalized for scheme http and https where
   * port 80 and port 443 respectively is set.
   *
   * The path component is set through either [path] or
   * [pathSegments]. When [path] is used, the provided string is
   * expected to be fully percent-encoded, and is used in its literal
   * form. When [pathSegments] is used, each of the provided segments
   * is percent-encoded and joined using the forward slash
   * separator. The percent-encoding of the path segments encodes all
   * characters except for the unreserved characters and the following
   * list of characters: `!$&'()*+,;=:@`. If the other components
   * calls for an absolute path a leading slash `/` is prepended if
   * not already there.
   *
   * The query component is set through either [query] or
   * [queryParameters]. When [query] is used the provided string is
   * expected to be fully percent-encoded and is used in its literal
   * form. When [queryParameters] is used the query is built from the
   * provided map. Each key and value in the map is percent-encoded
   * and joined using equal and ampersand characters. The
   * percent-encoding of the keys and values encodes all characters
   * except for the unreserved characters.
   *
   * The fragment component is set through [fragment].
   */
  Uri({scheme,
       this.userInfo: "",
       this.host: "",
       port: 0,
       String path,
       List<String> pathSegments,
       String query,
       Map<String, String> queryParameters,
       fragment: ""}) :
      scheme = _makeScheme(scheme),
      query = _makeQuery(query, queryParameters),
      fragment = _makeFragment(fragment) {
    // Perform scheme specific normalization.
    if (scheme == "http" && port == 80) {
      _port = 0;
    } else if (scheme == "https" && port == 443) {
      _port = 0;
    } else {
      _port = port;
    }
    // Fill the path.
    _path = _makePath(path, pathSegments);
  }

  /**
   * Creates a new `http` URI from authority, path and query.
   *
   * Examples:
   *
   *     // Create the URI http://example.org/path?q=abc.
   *     new Uri.http("google.com", "/search", { "q" : "dart" });http://example.org/path?q=abc.
   *     new Uri.http("user:pass@localhost:8080, "");  // http://user:pass@localhost:8080/
   *     new Uri.http("example.org, "a b");  // http://example.org/a%20b
   *     new Uri.http("example.org, "/a%2F");  // http://example.org/a%25%2F
   *
   * The `scheme` is always set to `http`.
   *
   * The `userInfo`, `host` and `port` components are set from the
   * [authority] argument.
   *
   * The `path` component is set from the [unencodedPath]
   * argument. The path passed must not be encoded as this constructor
   * encodes the path.
   *
   * The `query` component is set from the optional [queryParameters]
   * argument.
   */
  factory Uri.http(String authority,
                   String unencodedPath,
                   [Map<String, String> queryParameters]) {
    return _makeHttpUri("http", authority, unencodedPath, queryParameters);
  }

  /**
   * Creates a new `https` URI from authority, path and query.
   *
   * This constructor is the same as [Uri.http] except for the scheme
   * which is set to `https`.
   */
  factory Uri.https(String authority,
                    String unencodedPath,
                    [Map<String, String> queryParameters]) {
    return _makeHttpUri("https", authority, unencodedPath, queryParameters);
  }

  static Uri _makeHttpUri(String scheme,
                          String authority,
                          String unencodedPath,
                          Map<String, String> queryParameters) {
    var userInfo = "";
    var host = "";
    var port = 0;

    var hostStart = 0;
    // Split off the user info.
    bool hasUserInfo = false;
    for (int i = 0; i < authority.length; i++) {
      if (authority.codeUnitAt(i) == _AT_SIGN) {
        hasUserInfo = true;
        userInfo = authority.substring(0, i);
        hostStart = i + 1;
        break;
      }
    }
    // Split host and port.
    bool hasPort = false;
    for (int i = hostStart; i < authority.length; i++) {
      if (authority.codeUnitAt(i) == _COLON) {
        hasPort = true;
        host = authority.substring(hostStart, i);
        if (!host.isEmpty) {
          var portString = authority.substring(i + 1);
          if (portString.isNotEmpty) port = int.parse(portString);
        }
        break;
      }
    }
    if (!hasPort) {
      host = hasUserInfo ? authority.substring(hostStart) : authority;
    }

    return new Uri(scheme: scheme,
                   userInfo: userInfo,
                   host: host,
                   port: port,
                   pathSegments: unencodedPath.split("/"),
                   queryParameters: queryParameters);
  }

  /**
   * Returns the URI path split into its segments. Each of the
   * segments in the returned list have been decoded. If the path is
   * empty the empty list will be returned. A leading slash `/` does
   * not affect the segments returned.
   *
   * The returned list is unmodifiable and will throw [UnsupportedError] on any
   * calls that would mutate it.
   */
  List<String> get pathSegments {
    if (_pathSegments == null) {
      var pathToSplit = !path.isEmpty && path.codeUnitAt(0) == _SLASH
                        ? path.substring(1)
                        : path;
      _pathSegments = new UnmodifiableListView(
        pathToSplit == "" ? const<String>[]
                          : pathToSplit.split("/")
                                       .map(Uri.decodeComponent)
                                       .toList(growable: false));
    }
    return _pathSegments;
  }

  /**
   * Returns the URI query split into a map according to the rules
   * specified for FORM post in the [HTML 4.01 specification section 17.13.4]
   * (http://www.w3.org/TR/REC-html40/interact/forms.html#h-17.13.4
   * "HTML 4.01 section 17.13.4"). Each key and value in the returned map
   * has been decoded. If there is no query the empty map is returned.
   *
   * Keys in the query string that have no value are mapped to the
   * empty string.
   *
   * The returned map is unmodifiable and will throw [UnsupportedError] on any
   * calls that would mutate it.
   */
  Map<String, String> get queryParameters {
    if (_queryParameters == null) {
      _queryParameters = new _UnmodifiableMap(splitQueryString(query));
    }
    return _queryParameters;
  }

  static String _makeScheme(String scheme) {
    bool isSchemeLowerCharacter(int ch) {
      return ch < 128 &&
             ((_schemeLowerTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
    }

    bool isSchemeCharacter(int ch) {
      return ch < 128 && ((_schemeTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
    }

    if (scheme == null) return "";
    bool allLowercase = true;
    int length = scheme.length;
    for (int i = 0; i < length; i++) {
      int codeUnit = scheme.codeUnitAt(i);
      if (!isSchemeLowerCharacter(codeUnit)) {
        if (isSchemeCharacter(codeUnit)) {
          allLowercase = false;
        } else {
          throw new ArgumentError('Illegal scheme: $scheme');
        }
      }
    }

    return allLowercase ? scheme : scheme.toLowerCase();
  }

  String _makePath(String path, List<String> pathSegments) {
    if (path == null && pathSegments == null) return "";
    if (path != null && pathSegments != null) {
      throw new ArgumentError('Both path and pathSegments specified');
    }
    var result;
    if (path != null) {
      result = _normalize(path);
    } else {
      result = pathSegments.map((s) => _uriEncode(_pathCharTable, s)).join("/");
    }
    if ((hasAuthority || (scheme == "file")) &&
        result.isNotEmpty && !result.startsWith("/")) {
      return "/$result";
    }
    return result;
  }

  static String _makeQuery(String query, Map<String, String> queryParameters) {
    if (query == null && queryParameters == null) return "";
    if (query != null && queryParameters != null) {
      throw new ArgumentError('Both query and queryParameters specified');
    }
    if (query != null) return _normalize(query);

    var result = new StringBuffer();
    var first = true;
    queryParameters.forEach((key, value) {
      if (!first) {
        result.write("&");
      }
      first = false;
      result.write(Uri.encodeQueryComponent(key));
      if (value != null && !value.isEmpty) {
        result.write("=");
        result.write(Uri.encodeQueryComponent(value));
      }
    });
    return result.toString();
  }

  static String _makeFragment(String fragment) {
    if (fragment == null) return "";
    return _normalize(fragment);
  }

  static String _normalize(String component) {
    bool isNormalizedHexDigit(int digit) {
      return (_ZERO <= digit && digit <= _NINE) ||
          (_UPPER_CASE_A <= digit && digit <= _UPPER_CASE_F);
    }

    bool isLowerCaseHexDigit(int digit) {
      return _LOWER_CASE_A <= digit && digit <= _LOWER_CASE_F;
    }

    bool isUnreserved(int ch) {
      return ch < 128 &&
             ((_unreservedTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
    }

    int normalizeHexDigit(int index) {
      var codeUnit = component.codeUnitAt(index);
      if (isLowerCaseHexDigit(codeUnit)) {
        return codeUnit - 0x20;
      } else if (!isNormalizedHexDigit(codeUnit)) {
        throw new ArgumentError("Invalid URI component: $component");
      } else {
        return codeUnit;
      }
    }

    int decodeHexDigitPair(int index) {
      int byte = 0;
      for (int i = 0; i < 2; i++) {
        var codeUnit = component.codeUnitAt(index + i);
        if (_ZERO <= codeUnit && codeUnit <= _NINE) {
          byte = byte * 16 + codeUnit - _ZERO;
        } else {
          // Check ranges A-F (0x41-0x46) and a-f (0x61-0x66).
          codeUnit |= 0x20;
          if (_LOWER_CASE_A <= codeUnit &&
              codeUnit <= _LOWER_CASE_F) {
            byte = byte * 16 + codeUnit - _LOWER_CASE_A + 10;
          } else {
            throw new ArgumentError(
                "Invalid percent-encoding in URI component: $component");
          }
        }
      }
      return byte;
    }

    // Start building the normalized component string.
    StringBuffer result;
    int length = component.length;
    int index = 0;
    int prevIndex = 0;

    // Copy a part of the component string to the result.
    void fillResult() {
      if (result == null) {
        assert(prevIndex == 0);
        result = new StringBuffer(component.substring(prevIndex, index));
      } else {
        result.write(component.substring(prevIndex, index));
      }
    }

    while (index < length) {

      // Normalize percent encoding to uppercase and don't encode
      // unreserved characters.
      if (component.codeUnitAt(index) == _PERCENT) {
        if (length < index + 2) {
            throw new ArgumentError(
                "Invalid percent-encoding in URI component: $component");
        }

        var codeUnit1 = component.codeUnitAt(index + 1);
        var codeUnit2 = component.codeUnitAt(index + 2);
        var decodedCodeUnit = decodeHexDigitPair(index + 1);
        if (isNormalizedHexDigit(codeUnit1) &&
            isNormalizedHexDigit(codeUnit2) &&
            !isUnreserved(decodedCodeUnit)) {
          index += 3;
        } else {
          fillResult();
          if (isUnreserved(decodedCodeUnit)) {
            result.writeCharCode(decodedCodeUnit);
          } else {
            result.write("%");
            result.writeCharCode(normalizeHexDigit(index + 1));
            result.writeCharCode(normalizeHexDigit(index + 2));
          }
          index += 3;
          prevIndex = index;
        }
      } else {
        index++;
      }
    }
    if (result != null && prevIndex != index) fillResult();
    assert(index == length);

    if (result == null) return component;
    return result.toString();
  }

  static String _emptyIfNull(String val) => val != null ? val : '';

  static int _parseIntOrZero(String val) {
    if (val != null && val != '') {
      return int.parse(val);
    } else {
      return 0;
    }
  }

  static String _eitherOf(String val1, String val2) {
    if (val1 != null) return val1;
    if (val2 != null) return val2;
    return '';
  }

  // NOTE: This code was ported from: closure-library/closure/goog/uri/utils.js
  static final RegExp _splitRe = new RegExp(
      '^'
      '(?:'
        '([^:/?#.]+)'                   // scheme - ignore special characters
                                        // used by other URL parts such as :,
                                        // ?, /, #, and .
      ':)?'
      '(?://'
        '(?:([^/?#]*)@)?'               // userInfo
        '(?:'
          r'([\w\d\-\u0100-\uffff.%]*)'
                                        // host - restrict to letters,
                                        // digits, dashes, dots, percent
                                        // escapes, and unicode characters.
          '|'
          // TODO(ajohnsen): Only allow a max number of parts?
          r'\[([A-Fa-f0-9:.]*)\])'
                                        // IPv6 host - restrict to hex,
                                        // dot and colon.
        '(?::([0-9]+))?'                // port
      ')?'
      r'([^?#[]+)?'                     // path
      r'(?:\?([^#]*))?'                 // query
      '(?:#(.*))?'                      // fragment
      r'$');

  static const _COMPONENT_SCHEME = 1;
  static const _COMPONENT_USER_INFO = 2;
  static const _COMPONENT_HOST = 3;
  static const _COMPONENT_HOST_IPV6 = 4;
  static const _COMPONENT_PORT = 5;
  static const _COMPONENT_PATH = 6;
  static const _COMPONENT_QUERY_DATA = 7;
  static const _COMPONENT_FRAGMENT = 8;

  /**
   * Returns whether the URI is absolute.
   */
  bool get isAbsolute => scheme != "" && fragment == "";

  String _merge(String base, String reference) {
    if (base == "") return "/$reference";
    return "${base.substring(0, base.lastIndexOf("/") + 1)}$reference";
  }

  bool _hasDotSegments(String path) {
    if (path.length > 0 && path.codeUnitAt(0) == _COLON) return true;
    int index = path.indexOf("/.");
    return index != -1;
  }

  String _removeDotSegments(String path) {
    if (!_hasDotSegments(path)) return path;
    List<String> output = [];
    bool appendSlash = false;
    for (String segment in path.split("/")) {
      appendSlash = false;
      if (segment == "..") {
        if (!output.isEmpty &&
            ((output.length != 1) || (output[0] != ""))) output.removeLast();
        appendSlash = true;
      } else if ("." == segment) {
        appendSlash = true;
      } else {
        output.add(segment);
      }
    }
    if (appendSlash) output.add("");
    return output.join("/");
  }

  Uri resolve(String uri) {
    return resolveUri(Uri.parse(uri));
  }

  Uri resolveUri(Uri reference) {
    // From RFC 3986.
    String targetScheme;
    String targetUserInfo;
    String targetHost;
    int targetPort;
    String targetPath;
    String targetQuery;
    if (reference.scheme != "") {
      targetScheme = reference.scheme;
      targetUserInfo = reference.userInfo;
      targetHost = reference.host;
      targetPort = reference.port;
      targetPath = _removeDotSegments(reference.path);
      targetQuery = reference.query;
    } else {
      if (reference.hasAuthority) {
        targetUserInfo = reference.userInfo;
        targetHost = reference.host;
        targetPort = reference.port;
        targetPath = _removeDotSegments(reference.path);
        targetQuery = reference.query;
      } else {
        if (reference.path == "") {
          targetPath = this.path;
          if (reference.query != "") {
            targetQuery = reference.query;
          } else {
            targetQuery = this.query;
          }
        } else {
          if (reference.path.startsWith("/")) {
            targetPath = _removeDotSegments(reference.path);
          } else {
            targetPath = _removeDotSegments(_merge(this.path, reference.path));
          }
          targetQuery = reference.query;
        }
        targetUserInfo = this.userInfo;
        targetHost = this.host;
        targetPort = this.port;
      }
      targetScheme = this.scheme;
    }
    return new Uri(scheme: targetScheme,
                   userInfo: targetUserInfo,
                   host: targetHost,
                   port: targetPort,
                   path: targetPath,
                   query: targetQuery,
                   fragment: reference.fragment);
  }

  /**
   * Returns whether the URI has an [authority] component.
   */
  bool get hasAuthority => host != "";

  /**
   * Returns the origin of the URI in the form scheme://host:port for the
   * schemes http and https.
   *
   * It is an error if the scheme is not "http" or "https".
   *
   * See: http://www.w3.org/TR/2011/WD-html5-20110405/origin-0.html#origin
   */
  String get origin {
    if (scheme == "" || host == null || host == "") {
      throw new StateError("Cannot use origin without a scheme: $this");
    }
    if (scheme != "http" && scheme != "https") {
      throw new StateError(
        "Origin is only applicable schemes http and https: $this");
    }
    if (port == 0) return "$scheme://$host";
    return "$scheme://$host:$port";
  }

  void _writeAuthority(StringSink ss) {
    _addIfNonEmpty(ss, userInfo, userInfo, "@");
    ss.write(host == null ? "null" :
             host.contains(':') ? '[$host]' : host);
    if (port != 0) {
      ss.write(":");
      ss.write(port.toString());
    }
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    _addIfNonEmpty(sb, scheme, scheme, ':');
    if (hasAuthority || (scheme == "file")) {
      sb.write("//");
      _writeAuthority(sb);
    }
    sb.write(path);
    _addIfNonEmpty(sb, query, "?", query);
    _addIfNonEmpty(sb, fragment, "#", fragment);
    return sb.toString();
  }

  bool operator==(other) {
    if (other is! Uri) return false;
    Uri uri = other;
    return scheme == uri.scheme &&
        userInfo == uri.userInfo &&
        host == uri.host &&
        port == uri.port &&
        path == uri.path &&
        query == uri.query &&
        fragment == uri.fragment;
  }

  int get hashCode {
    int combine(part, current) {
      // The sum is truncated to 30 bits to make sure it fits into a Smi.
      return (current * 31 + part.hashCode) & 0x3FFFFFFF;
    }
    return combine(scheme, combine(userInfo, combine(host, combine(port,
        combine(path, combine(query, combine(fragment, 1)))))));
  }

  static void _addIfNonEmpty(StringBuffer sb, String test,
                             String first, String second) {
    if ("" != test) {
      sb.write(first);
      sb.write(second);
    }
  }

  /**
   * Encode the string [component] using percent-encoding to make it
   * safe for literal use as a URI component.
   *
   * All characters except uppercase and lowercase letters, digits and
   * the characters `!$&'()*+,;=:@` are percent-encoded. This is the
   * set of characters specified in RFC 2396 and the which is
   * specified for the encodeUriComponent in ECMA-262 version 5.1.
   *
   * When manually encoding path segments or query components remember
   * to encode each part separately before building the path or query
   * string.
   *
   * For encoding the query part consider using
   * [encodeQueryComponent].
   *
   * To avoid the need for explicitly encoding use the [pathSegments]
   * and [queryParameters] optional named arguments when constructing
   * a [Uri].
   */
  static String encodeComponent(String component) {
    return _uriEncode(_unreserved2396Table, component);
  }

  /**
   * Encode the string [component] according to the HTML 4.01 rules
   * for encoding the posting of a HTML form as a query string
   * component.
   *
   * Spaces will be replaced with plus and all characters except for
   * uppercase and lowercase letters, decimal digits and the
   * characters `-._~`. Note that the set of characters encoded is a
   * superset of what HTML 4.01 says as it refers to RFC 1738 for
   * reserved characters.
   *
   * When manually encoding query components remember to encode each
   * part separately before building the query string.
   *
   * To avoid the need for explicitly encoding the query use the
   * [queryParameters] optional named arguments when constructing a
   * [Uri].
   *
   * See http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.2 for more
   * details.
   */
  static String encodeQueryComponent(String component) {
    return _uriEncode(_unreservedTable, component, spaceToPlus: true);
  }

  /**
   * Decodes the percent-encoding in [encodedComponent].
   *
   * Note that decoding a URI component might change its meaning as
   * some of the decoded characters could be characters with are
   * delimiters for a given URI componene type. Always split a URI
   * component using the delimiters for the component before decoding
   * the individual parts.
   *
   * For handling the [path] and [query] components consider using
   * [pathSegments] and [queryParameters] to get the separated and
   * decoded component.
   */
  static String decodeComponent(String encodedComponent) {
    return _uriDecode(encodedComponent);
  }

  static String decodeQueryComponent(String encodedComponent) {
    return _uriDecode(encodedComponent, plusToSpace: true);
  }

  /**
   * Encode the string [uri] using percent-encoding to make it
   * safe for literal use as a full URI.
   *
   * All characters except uppercase and lowercase letters, digits and
   * the characters `!#$&'()*+,-./:;=?@_~` are percent-encoded. This
   * is the set of characters specified in in ECMA-262 version 5.1 for
   * the encodeURI function .
   */
  static String encodeFull(String uri) {
    return _uriEncode(_encodeFullTable, uri);
  }

  /**
   * Decodes the percent-encoding in [uri].
   *
   * Note that decoding a full URI might change its meaning as some of
   * the decoded characters could be reserved characters. In most
   * cases an encoded URI should be parsed into components using
   * [Uri.parse] before decoding the separate components.
   */
  static String decodeFull(String uri) {
    return _uriDecode(uri);
  }

  /**
   * Returns the [query] split into a map according to the rules
   * specified for FORM post in the
   * [HTML 4.01 specification section 17.13.4]
   * (http://www.w3.org/TR/REC-html40/interact/forms.html#h-17.13.4
   * "HTML 4.01 section 17.13.4"). Each key and value in the returned
   * map has been decoded. If the [query]
   * is the empty string an empty map is returned.
   *
   * Keys in the query string that have no value are mapped to the
   * empty string.
   */
  static Map<String, String> splitQueryString(String query) {
    return query.split("&").fold({}, (map, element) {
      int index = element.indexOf("=");
      if (index == -1) {
        if (element != "") map[decodeQueryComponent(element)] = "";
      } else if (index != 0) {
        var key = element.substring(0, index);
        var value = element.substring(index + 1);
        map[Uri.decodeQueryComponent(key)] = decodeQueryComponent(value);
      }
      return map;
    });
  }

  // Frequently used character codes.
  static const int _PERCENT = 0x25;
  static const int _PLUS = 0x2B;
  static const int _SLASH = 0x2F;
  static const int _ZERO = 0x30;
  static const int _NINE = 0x39;
  static const int _COLON = 0x3A;
  static const int _AT_SIGN = 0x40;
  static const int _UPPER_CASE_A = 0x41;
  static const int _UPPER_CASE_F = 0x46;
  static const int _LOWER_CASE_A = 0x61;
  static const int _LOWER_CASE_F = 0x66;

  /**
   * This is the internal implementation of JavaScript's encodeURI function.
   * It encodes all characters in the string [text] except for those
   * that appear in [canonicalTable], and returns the escaped string.
   */
  static String _uriEncode(List<int> canonicalTable,
                    String text,
                    {bool spaceToPlus: false}) {
    byteToHex(int v) {
      final String hex = '0123456789ABCDEF';
      return '%${hex[v >> 4]}${hex[v & 0x0f]}';
    }

    StringBuffer result = new StringBuffer();
    for (int i = 0; i < text.length; i++) {
      int ch = text.codeUnitAt(i);
      if (ch < 128 && ((canonicalTable[ch >> 4] & (1 << (ch & 0x0f))) != 0)) {
        result.write(text[i]);
      } else if (spaceToPlus && text[i] == " ") {
        result.write("+");
      } else {
        if (ch >= 0xD800 && ch < 0xDC00) {
          // Low surrogate. We expect a next char high surrogate.
          ++i;
          int nextCh = text.length == i ? 0 : text.codeUnitAt(i);
          if (nextCh >= 0xDC00 && nextCh < 0xE000) {
            // convert the pair to a U+10000 codepoint
            ch = 0x10000 + ((ch - 0xD800) << 10) + (nextCh - 0xDC00);
          } else {
            throw new ArgumentError('Malformed URI');
          }
        }
        for (int codepoint in codepointsToUtf8([ch])) {
          result.write(byteToHex(codepoint));
        }
      }
    }
    return result.toString();
  }

  /**
   * Convert a byte (2 character hex sequence) in string [s] starting
   * at position [pos] to its ordinal value
   */
  static int _hexCharPairToByte(String s, int pos) {
    int byte = 0;
    for (int i = 0; i < 2; i++) {
      var charCode = s.codeUnitAt(pos + i);
      if (0x30 <= charCode && charCode <= 0x39) {
        byte = byte * 16 + charCode - 0x30;
      } else {
        // Check ranges A-F (0x41-0x46) and a-f (0x61-0x66).
        charCode |= 0x20;
        if (0x61 <= charCode && charCode <= 0x66) {
          byte = byte * 16 + charCode - 0x57;
        } else {
          throw new ArgumentError("Invalid URL encoding");
        }
      }
    }
    return byte;
  }

  /**
   * A JavaScript-like decodeURI function. It unescapes the string [text] and
   * returns the unescaped string.
   */
  static String _uriDecode(String text, {bool plusToSpace: false}) {
    StringBuffer result = new StringBuffer();
    List<int> codepoints = new List<int>();
    for (int i = 0; i < text.length;) {
      int ch = text.codeUnitAt(i);
      if (ch != _PERCENT) {
        if (plusToSpace && ch == _PLUS) {
          result.write(" ");
        } else {
          result.writeCharCode(ch);
        }
        i++;
      } else {
        codepoints.clear();
        while (ch == _PERCENT) {
          if (++i > text.length - 2) {
            throw new ArgumentError('Truncated URI');
          }
          codepoints.add(_hexCharPairToByte(text, i));
          i += 2;
          if (i == text.length) break;
          ch = text.codeUnitAt(i);
        }
        result.write(decodeUtf8(codepoints));
      }
    }
    return result.toString();
  }

  // Tables of char-codes organized as a bit vector of 128 bits where
  // each bit indicate whether a character code on the 0-127 needs to
  // be escaped or not.

  // The unreserved characters of RFC 3986.
  static const _unreservedTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //                           -.
      0x6000,   // 0x20 - 0x2f  0000000000000110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // The unreserved characters of RFC 2396.
  static const _unreserved2396Table = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !     '()*  -.
      0x6782,   // 0x20 - 0x2f  0100000111100110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Table of reserved characters specified by ECMAScript 5.
  static const _encodeFullTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               ! #$ &'()*+,-./
      0xf7da,   // 0x20 - 0x2f  0101101111101111
                //              0123456789:; = ?
      0xafff,   // 0x30 - 0x3f  1111111111110101
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the scheme.
  static const _schemeTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //                         + -.
      0x6800,   // 0x20 - 0x2f  0000000000010110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ
      0x07ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz
      0x07ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in scheme except for upper case letters.
  static const _schemeLowerTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //                         + -.
      0x6800,   // 0x20 - 0x2f  0000000000010110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //
      0x0000,   // 0x40 - 0x4f  0111111111111111
                //
      0x0000,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz
      0x07ff];  // 0x70 - 0x7f  1111111111100010

  // Sub delimiter characters combined with unreserved as of 3986.
  // sub-delims  = "!" / "$" / "&" / "'" / "(" / ")"
  //             / "*" / "+" / "," / ";" / "="
  // RFC 3986 section 2.3.
  // unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
  static const _subDelimitersTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-.
      0x7fd2,   // 0x20 - 0x2f  0100101111111110
                //              0123456789 ; =
      0x2bff,   // 0x30 - 0x3f  1111111111010100
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the path as of RFC 3986.
  // RFC 3986 section 3.3.
  // pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
  static const _pathCharTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-.
      0x7fd2,   // 0x20 - 0x2f  0100101111111110
                //              0123456789:; =
      0x2fff,   // 0x30 - 0x3f  1111111111110100
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the query as of RFC 3986.
  // RFC 3986 section 3.4.
  // query = *( pchar / "/" / "?" )
  static const _queryCharTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-./
      0xffd2,   // 0x20 - 0x2f  0100101111111111
                //              0123456789:; = ?
      0xafff,   // 0x30 - 0x3f  1111111111110101
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010
}

class _UnmodifiableMap<K, V> implements Map<K, V> {
  final Map _map;
  const _UnmodifiableMap(this._map);

  bool containsValue(Object value) => _map.containsValue(value);
  bool containsKey(Object key) => _map.containsKey(key);
  V operator [](Object key) => _map[key];
  void operator []=(K key, V value) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  V putIfAbsent(K key, V ifAbsent()) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  addAll(Map other) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  V remove(Object key) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  void clear() {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  void forEach(void f(K key, V value)) => _map.forEach(f);
  Iterable<K> get keys => _map.keys;
  Iterable<V> get values => _map.values;
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}
