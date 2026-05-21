# AGENTS.md

## Purpose

This repository contains a Middleman-based personal site, a small Sinatra API, and a separate Slidev deck under `slides/`.

Use this file as the default operating guide when making changes in this repo.

## Environment

- Run Ruby commands with the Homebrew Ruby environment loaded:
  - `source ~/.zshrc && bundle exec ...`
- The system Ruby may not have the right Bundler version from `Gemfile.lock`.
- The main app root is this directory.
- The Slidev project is isolated under `slides/`.

## Main Areas

- `source/`: site pages, templates, stylesheets
- `helpers/`: Middleman helper modules
- `lib/`: support code such as `tabelog.rb`, `video.rb`, and the Sinatra API server
- `data/`: structured site data consumed by Middleman
- `spec/`: RSpec tests
- `slides/`: separate Node/Slidev presentation project

## Helpers And Specs

- Keep `helpers/*.rb` and `spec/helpers/*_spec.rb` consistent.
- Prefer one spec file per helper module.
- Current mapping:
  - `helpers/site_helpers.rb` <-> `spec/helpers/site_helpers_spec.rb`
  - `helpers/page_metadata_helpers.rb` <-> `spec/helpers/page_metadata_helpers_spec.rb`
  - `helpers/embed_helpers.rb` <-> `spec/helpers/embed_helpers_spec.rb`
  - `helpers/daylog_helpers.rb` <-> `spec/helpers/daylog_helpers_spec.rb`
  - `helpers/diary_index_helpers.rb` <-> `spec/helpers/diary_index_helpers_spec.rb`
  - `helpers/link_helpers.rb` <-> `spec/helpers/link_helpers_spec.rb`
  - `helpers/navigation_helpers.rb` <-> `spec/helpers/navigation_helpers_spec.rb`
  - `helpers/tag_helpers.rb` <-> `spec/helpers/tag_helpers_spec.rb`
- `helpers/diary_media_helpers.rb` is an internal split of `DiaryIndexHelpers`; cover it through `spec/helpers/diary_index_helpers_spec.rb` rather than creating a separate top-level helper spec unless the module boundary changes.

## Common Commands

- Run all tests:
  - `source ~/.zshrc && bundle exec rspec`
- Run helper specs only:
  - `source ~/.zshrc && bundle exec rspec spec/helpers`
- Run the default rake task:
  - `source ~/.zshrc && bundle exec rake`
- Run RuboCop:
  - `source ~/.zshrc && bundle exec rubocop`
- Start the site and API together:
  - `make run`
- Build the site:
  - `make build`
- Rebuild tags:
  - `make tags`

## Testing Guidance

- Prefer the smallest relevant spec scope before running the full suite.
- When updating helper output, adjust helper specs to match the actual rendered HTML if the implementation change is intentional.
- Some runs print a LiveReload port warning from Middleman. If RSpec finishes with failures unrelated to that warning, treat the warning as non-blocking.
- `spec/lib/tabelog_spec.rb` should match the actual formatter behavior, including trailing newline behavior and Unicode normalization.

## Editing Guidance

- Preserve the existing Middleman patterns in `config.rb`, `source/layouts`, and helpers.
- Prefer small helper modules over growing catch-all helper files.
- Use `git mv` for renames so helper/spec history stays traceable.
- Do not assume `slides/` uses the same tooling as the main site; use Node commands there and Ruby commands in the repo root.
- Do not embed inline `style` attributes in generated HTML; add classes and define presentation in `source/stylesheets/style.css`.

## Style

- RuboCop config lives in `.rubocop.yml`.
- `Metrics/ModuleLength` max is 130.
- `Metrics/MethodLength` max is 25.
- Specs are exempt from some line-length and block-length limits.

## Validation Before Finishing

For Ruby changes:

- Run targeted specs first.
- Then run `source ~/.zshrc && bundle exec rspec` if the change could affect shared behavior.

For `slides/` changes:

- Use the scripts in `slides/package.json`.
