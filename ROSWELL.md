# Roswell workflow for this repo

This repo runs Common Lisp tasks via **Roswell**. Most of the time you should use the **Makefile**
targets, which wrap the Roswell commands in a consistent way.

## Canonical commands

From the repo root:

### Run tests (preferred)

```bash
make test
```

This runs a clean Roswell session:

```bash
ros -Q script scripts/test.ros
```

### Start a REPL (optional)

If scripts/repl.ros exists:

```bash
make repl
```

Which runs:

```bash
ros -Q script scripts/repl.ros
```

## Bootstrap fallback (only if scripts are missing)

If scripts/test.ros does not exist yet (e.g., early scaffold work), run:

```bash
ros -Q run \
  --eval '(require :asdf)' \
  --load 'cl-vctrs-lite.asd' \
  --eval '(asdf:test-system :cl-vctrs-lite/test)' \
  --eval '(uiop:quit 0)' \
  --quit
```

After bootstrapping, create scripts/test.ros so make test works.

## Required script: scripts/test.ros

Create the file scripts/test.ros with the following content and make it executable:

```lisp
#!/usr/bin/env ros
;; -*- mode: lisp; -*-
;; scripts/test.ros — deterministic test runner (run from repo root)

(require :asdf)

(let* ((root (uiop:getcwd))
       (asd  (merge-pathnames "cl-vctrs-lite.asd" root)))
  (asdf:load-asd asd))

(handler-case
    (progn
      (asdf:test-system :cl-vctrs-lite/test)
      (format t "~&OK~%")
      (uiop:quit 0))
  (error (e)
    (format *error-output* "~&TESTS FAILED: ~a~%" e)
    (uiop:quit 1)))
```

Make it executable:

```bash
chmod +x scripts/test.ros
```

## Optional script: scripts/repl.ros

If you add it later, also make it executable:
```bash
chmod +x scripts/repl.ros
```
