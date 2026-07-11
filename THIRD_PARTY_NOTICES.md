# Third-Party Notices

## SIL libpalaso versification data

The King James versification table in `lib/versification_profile.dart` was
generated from the English Paratext versification resource in SIL libpalaso:

- Source: `SIL.Scripture/Resources/eng.vrs.txt`
- Commit: `ba68a4a7a7509766a1aa66d7664cff3ddf95c195`
- URL: https://github.com/sillsdev/libpalaso/blob/ba68a4a7a7509766a1aa66d7664cff3ddf95c195/SIL.Scripture/Resources/eng.vrs.txt

The source rows were converted from `chapter:maximumVerse` pairs to Dart
integer lists. Only the conventional 66-book Protestant canon was retained.
KJV-specific differences are described below.

The MIT License (MIT)

Copyright (c) 2007-2025 SIL Global

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

## OpenBibleInfo KJV-specific versification data

SIL's broad English table is not identical to KJV versification. Revelation
12 was changed from a maximum verse of 18 to 17, and 3 John was changed from
15 to 14, matching the MIT-licensed OpenBibleInfo default and KJV tables:

- Source: `cjs/en_bcv_parser.js`
- Commit: `964a71cbd29f6697ee4567150bb811fb26d13de3`
- URL: https://github.com/openbibleinfo/Bible-Passage-Reference-Parser/blob/964a71cbd29f6697ee4567150bb811fb26d13de3/cjs/en_bcv_parser.js

The resulting table contains 31,102 verses. It was independently cross-checked
against CrossWire JSword's `SystemKJV` table; no JSword code or data is copied
into this package.

Copyright (c) 2011-2026 Stephen Smith

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
