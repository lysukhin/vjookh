# Dictionary attribution

`en.txt` and `ru.txt` are hunspell `.dic` wordlists derived from the
[LibreOffice dictionaries](https://github.com/LibreOffice/dictionaries):

- `en.txt` — from `en/en_US.dic` (SCOWL-derived; permissive: BSD/MIT-style).
- `ru.txt` — from `ru_RU/ru_RU.dic` (BSD / GPL-compatible).

Only the stem (text before `/AFFIXFLAGS`) is used for membership checks; the
hunspell affix (`.aff`) rules are not bundled. These files retain their
upstream licenses; the application code is GPL-3.0 (see top-level `LICENSE`),
which is compatible with the above.
