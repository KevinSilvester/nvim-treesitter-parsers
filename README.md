# nvim-treesitter-parsers

A way of keeping track of parsers used by [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter).

---

### How it works

A daily cron job is run to check for any updates/changes to the list of parsers used by `nvim-treesitter`.

Any changes detected will trigger an updated sequence and will be reflected on [`parsers.json`](./parsers.json).

All updates will be tagged with the shortened `commit_id` of `nvim-treesitter` that triggered the update.

Updates will also be written to written to `CHANGELOG.json` with the tag name, timestamp, changed/updated parsers list and permalink to the raw `parser.min.json`.
