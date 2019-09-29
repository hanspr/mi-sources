# Perl Plugin

The perl plugin provides some extra niceties for the Perl programming language.

**Key Bindings**

- `F9` Toggle auto ";" at the end of the line
    - It will add ";" at the end of each line, when required
- `Ctrl-Enter` o `Alt-Enter` (check your terminal)
    - Inserts a new line at the end and jumps to the next line, even if you are at the middle of a line. Helps to complement the auto ";"
- `F11` Intent the complete buffer
- `F12` Toggle Strict or Dirty Compile to test the current script
- `Save` Saves and test file with : `perl -c` it adds Strict depending on the setting from `F12`
    - If no errors, display a Success message at the bottom
    - If there is an error. Will split the window, show the full message and place the cursor at the line mentioned by the error description
