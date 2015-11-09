# MdInclude

This preprocessor for Markdown combines multiple files into one file using commands in them:
```markdown
#include filename.md
```

Inspired by [markdown-include](https://github.com/sethen/markdown-include).

## Why does this preprocessor exist?

Well, `MdInclude` is simpler and has different config file format.

## Usage

Create file `build-markdown.json` with contents:
```json
{
  "files": [
    "filename1.md",
    "filename2.md"
  ]
}
```

MdInclude will read files in "files" section and create result files. Name of result file starts with underscore `_`.

To include contents of one file (`included.md`) into another (`main.md`) add string into last file (`main.md`):
```markdown
#include included.md
```

Run MdInclude to create combined files (replace *directory* with your actual directory with `build-markdown.json`):

    ruby md-include.rb directory

If a file (`main.md`) includes another file (`included.md`) that has been parsed during work of this script it will use parsed version (`_included.md`).

## Test

Install dependencies with `bundle install` and run `bundle exec rspec`.
