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


[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis