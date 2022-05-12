# publish_docs (not yet on pub.dev)

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: BSD-3-Clause][license_badge]][license_link]

Publish your documentation to GitHub Pages!

_This package is in a pre-release form and not yet ready for general
use. Feel free to try it out, but understand that the public usage and
integration steps may change significantly before the first public
release._

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

We use the `git format-patch` command to create each documentation
update. This patch is then applied to the GitHub Pages branch.

[Adding docs changes to the repo](#adding-docs-changes-to-the-repo)
has more details on why we do this, and
[gh_pages_patch.dart][pages_patch_file] contains a good bit of the
relevant code.

Here is a rundown of the other kinds of commands we run, with
explanations of why they're in this project:

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
`git rev-list`. Please refer to the source code itself (and the
[GitCommands class][git_commands_class] in particular) for a better
understanding of what `git` library functions we call.

#### Can I change the `git` dependency?

As long as this library has null-safety and lets us run `git` commands,
it doesn't matter too much which version is in use. There should be no
problem upgrading to newer versions of this library.

### dartdoc

#### Why use `dartdoc`?

We use this library to generate documentation for dart code. While
there are some limitations (see [Limitations](#limitations)),
`dartdoc` is remarkably good at creating readable documentation. It
handles all the cross-references and annotation information, since it
builds a full package graph of all the code and comments in your
project. This makes `dartdoc` a very powerful basis for _any_ kind of
visual representation of your project, not just documentation.

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

For the most part, you can think of the `:generate` command as a
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

### Preparation

Your project must work with `dartdoc` before using `publish_docs`.

1. Run `dart analyze`. Fix all errors (warnings _should_ be fixed, but
the library will still be able to create docs if there are warnings).
2. Make a `dartdoc_options.yaml` if you don't have one already.
3. Run `dart doc` to use the version of `dartdoc` that's bundled with
Dart's SDK.

If `dart doc` finishes successfully, without any errors, then you're
ready to integrate `publish_docs` into your project. As a special
case: if there is a version conflict or a version-specific bug in the
`dart doc` output (such as [Issue 2934][dartdoc_2934]), then you may
want to skip ahead to the next step anyway.

### Integration

Add `publish_docs` to your project's pubspec.yaml as a
[dev-dependency][dart_dev_dependency]. Run the appropriate `pub get`
command for your project (probably `dart pub get` or
`flutter pub get`) to update your project's pubspec.lock.

...That's basically it. You can now use a `pub run` command to try out
the tool. We recommend starting off with the `publish_docs` command:

```shell
# For Dart projects
dart pub run publish_docs
# For Flutter projects
flutter pub run publish_docs
```

### Customisation

#### Basics

By default, we make use of the following 4 directories:

`doc/api/` - the default output directory for `:generate`.

`doc/assets/` - the default directory for runtime resources.

`docs/api/` - the default output directory for `:commit`.

You can change the appearance and behavior of the generated docs by
adding any of the currently-supported files to `doc/assets/`. We will
automatically use our [bundled resources](lib/resources/dartdoc-5.1.0)
to add any important files that you didn't provide there.

#### Supported files

_As seen in [the generated list][dartdoc_asset_list]._

- `docs.dart.js`
- `docs.dart.js.map`
- `favicon.png`
- `github.css`
- `highlight.pack.js`
- `play_button.svg`
- `readme.md`
- `styles.css`

Note that this list is subject to change in future releases of the
`dartdoc` library. Until the `dartdoc` library API stabilises, you
should pay careful attention the exact version of `publish_docs` you
use.

## Limitations

### Adding docs changes to the repo

Since documentation tends to take up an awful lot of space, we try to
reuse existing files where possible. To that end we generate new docs
right on top of existing documentation, and create a patch out of the
diff between the old and new.

We make three assumptions about the process:

1. Generated documentation is stored on its own branch.
2. Each commit on that branch has just one version of the docs.
3. That branch already exists and has at least one commit.

This matches a classic 'gh-pages' approach to GitHub Pages, but you
don't _have_ to follow that. The settings part of your GitHub repo
lets you choose to load documentation from any branch, not just one
called 'gh-pages', and of course the one-version-per-commit thing is
just a convention.

Keeping those three assumptions, though, does make it a lot easier for
this project to work properly. In a future version of `publish_docs`,
perhaps we'll support more kinds of repo configuration. The wiki for a
GitHub project is only a special kind of Git Repository, after all, so
there might even be an option to upload markdown-style docs into that.

### Our stance on command-line `dartdoc` options

There are things that `dartdoc` can do that are only configured with
command-line flags. Other options can only be configured through a
`dartdoc_options.yaml` file. And then there are options that can be
defined in either way.

Roughly speaking, command-line-only options have the greatest impact.
They tend to change the output in significant ways, from the obvious
`--help` and `--format`, to the more subtle `--inject-html` and
`--validate-links`.

For this reason, we make an effort to avoid using command-line-only
flags where alternatives exist. The main exception is the
`--resources-dir` option, which cannot be configured in any other way.
We provide a value of `doc/assets/` for that.


[license_badge]: https://img.shields.io/badge/license-BSD_3_Clause-blue.svg
[license_link]: https://opensource.org/licenses/BSD-3-Clause
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[dart_dev_dependency]: https://dart.dev/tools/pub/dependencies#dev-dependencies
[dartdoc_js_commit]: https://github.com/dart-lang/dartdoc/commit/a33ec963eb5b9aa91
[dartdoc_library]: https://pub.dev/documentation/dartdoc/5.0.1/dartdoc/dartdoc-library.html
[dartdoc_pub_meta]: https://pub.dev/documentation/dartdoc/5.0.1/dartdoc/PackageMeta-class.html
[dartdoc_2934]: https://github.com/dart-lang/dartdoc/issues/2934
[dartdoc_asset_list]: https://github.com/dart-lang/dartdoc/blob/26d38618/lib/src/generator/html_resources.g.dart
[doxygen_diagrams]: https://www.doxygen.nl/manual/diagrams.html
[git_commands_class]: lib/src/git/commands.dart
[pages_patch_file]: lib/src/operation/gh_pages_patch.dart
