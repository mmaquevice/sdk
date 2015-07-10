* `dart:io`
  * Added two new file modes, `WRITE_ONLY` and `WRITE_ONLY_APPEND` for
    opening a file write only.
    [eaeecf2](https://github.com/dart-lang/sdk/commit/eaeecf2ed13ba6c7fbfd653c3c592974a7120960)

  * An issue where HTTP requests were sometimes made even though `--offline` was
    passed to `pub get` or `pub upgrade` has been fixed.

  * A bug with `--offline` that caused an unhelpful error message has been
    fixed.

  * A crashing bug involving transformers that only apply to non-public code has
    been fixed.
