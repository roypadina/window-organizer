# Security Policy

## Reporting a Vulnerability

Window Organizer runs un-sandboxed with Accessibility permission and can close, quit and
force quit other apps, so security reports are taken seriously.
Please **do not** open a public issue for security problems.

Instead, use GitHub's private vulnerability reporting
(**Security → Report a vulnerability** on this repository).

You'll get an acknowledgement within a few days. Once a fix is available it will be released
and the report disclosed, with credit unless you prefer otherwise.

## Scope

Window Organizer runs entirely on-device and makes no network connections. Relevant areas:
the global shortcut handler, the Accessibility window actions (minimize / close), and app
termination through `NSRunningApplication`.
