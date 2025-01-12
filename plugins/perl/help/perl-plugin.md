# Perl Plugin

The perl plugin provides some extra niceties for the Perl programming language.

**Key Bindings**

- `Alt-Enter`
    - Inserts a ; and a new line at the end and jumps to the next line.
- `F10` Enable - Disable perltidy.
- `F11` Enable - Disable syntaxcheck
- `F12` Toggle Strict (-cw -Mstrict) or Dirty (-cX) test the current script in strict mode
- `Save` If Syntax check is enabled. Saves and test file with : strict or dirty it adds Strict depending on the setting from `F12`
    - If no errors, display a Success message at the bottom
    - If there is an error. Will split the window, show the full message and place the cursor at the line mentioned by the error description
