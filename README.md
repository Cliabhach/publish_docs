# publish_docs

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

Publish your documentation to GitHub Pages!

## Concept

Strictly speaking, this does everything _but_ the actual publish step
for you. That last step is easy to perform, though - it's nothing more
than `git push`.

We make the following assumptions about your project and what output
you would like:

1. The project uses [`git` version control](https://git-scm.com/)
2. The project doesn't share its git repository with other projects
3. All the generated docs should use the same theming
4. You already have a `gh-pages` branch
5. Your GitHub Pages settings are configured in a certain way

## Dependencies

The only direct runtime dependencies are `dartdoc` and `git`.

### git

#### Why use `git`?

### dartdoc

#### Why use `dartdoc`?


[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis