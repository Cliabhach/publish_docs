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

We use this library to execute `git` commands, which let us query and
manipulate the project's git repository. The library also offers handy
data models for `Commit`s and `BranchReference`s, among other
abstractions. It is not an exaggeration to say that our project here
could not exist if the `git` library was not already published.

While we do have _access_ to do other things, our code actively tries
to avoid damaging your git repository or deleting any important files.
An established library like this one makes it easier for us to avoid
the really dangerous things.

#### How do we use `git`?

First off, our use of the `git format-patch` command is slightly
unusual. The [TODO: link]() has more details on why.

Here is a rundown of the kinds of commands we run, with explanations
of why they're in this project:

| Command       | Our usage                                        |
|---------------|--------------------------------------------------|
| git add       | Add newly-generated docs to the git index        |
| git am        | Apply the output of format-patch to gh-pages     |
| git checkout  | 1: Load prior docs, 2: Switch to gh-pages branch |
| git commit    | Create one of two temp commits for format-patch  |
| git rev-parse | Read in the short hash for a specific commit     |
| git reset     | Remove the two temp commits for format-patch     |
| git stash     | Save locally-changed files so we don't edit them |

In addition to the above, we do use some functions exposed by the
library itself. For example, `GitDir.commits` internally invokes
`git rev-list`. Please refer to the source code itself for a better
understanding of what `git` library functions we call.

#### Can I change the `git` dependency?

As long as this library has null-safety and lets us run `git` commands,
it doesn't matter too much which version is in use. There should be no
problem upgrading to newer versions.

### dartdoc

#### Why use `dartdoc`?

We use this library to generate documentation for dart code. While
there are some limitations (see [TODO: write section]()), `dartdoc` is
remarkably good at creating readable documentation. It handles all the
cross-references and annotation information, since it builds a full
package graph of all the code and comments in your project. This makes
`dartdoc` a very powerful basis for any kind of visual representation
of your project.

It's easy to imagine `dartdoc` supporting even more features in the
future, such as graphs [in the style of doxygen][doxygen_diagrams].

#### How do we use `dartdoc`?

We integrate into the `dartdoc` library through two main avenues:

1. The public API. This is [still experimental][dartdoc_library], as
of Dartdoc 5.0.1, and may change in future versions.
2. Your project's `dartdoc_options.yaml` file. This is stable - you
might even have one of these defined in your repository.
3. Custom runtime resources. This is _very_ new, and the main reason
why we require such a recent version of the `dartdoc` library.

For the most part, you can think of the `generateDocs` command as a
drop-in replacement for `dart doc`. With no additional configuration,
you'll get the same documentation output you've come to expect, along
with our replacement for the default `dartdoc` assets.

When you run `updateGitHubDocs` or `updateGitHubPages`, the situation
is a little different. Here, we do a number of git operations both
before and after the calls into `dartdoc`, and we make great use of
the code analysis/metadata offered by [PubMeta][dartdoc_pub_meta].

#### Can I change the `dartdoc` dependency?

Yes, but with a caveat - make sure that you choose a version that is
recent enough to include the dart-based navigation code. Before
[the frontend JS was fully converted to Dart][dartdoc_js_commit], the
files that could be copied with the `resourcesDir`/`resources-dir`
option had different names.

## Usage


[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[dartdoc_js_commit]: https://github.com/dart-lang/dartdoc/commit/a33ec963eb5b9aa91
[dartdoc_library]: https://pub.dev/documentation/dartdoc/5.0.1/dartdoc/dartdoc-library.html
[dartdoc_pub_meta]: https://pub.dev/documentation/dartdoc/5.0.1/dartdoc/PackageMeta-class.html
[doxygen_diagrams]: https://www.doxygen.nl/manual/diagrams.html
