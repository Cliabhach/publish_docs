// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/branch_update.dart';
import 'package:publish_docs/src/operation/gh_pages_patch.dart';
import 'package:publish_docs/src/util/git_util.dart';

/// A class for adding a Git commit to a branch.
///
/// This uses custom logic extended upon the [GitCommands] class.
///
/// # Why?
///
/// GitHub Pages only knows how to read from two possible locations:
///
/// 1. the API root
/// 2. the 'docs/' directory
///
/// We point it at 'docs/'. The general structure of this method is to generate
/// docs on top of the latest version of those files, and then run some git
/// commands to turn that into a diff. We can then apply the diff on top of the
/// `gh-pages` branch to create a straightforward commit.
///
/// # How?
///
/// Rough overview of git commands:
///
/// ```bash
/// git checkout gh-pages docs/api
/// #(we generate the docs at this point)
/// git diff > localfile.patch
/// git reset --hard HEAD
/// git checkout gh-pages
/// git am localfile.patch
/// git switch -
/// ```
///
/// # Additional notes
///
/// We always try to return to the original branch state at the end of the
/// process. If there are locally-modified files outside of `docs/api/` then we
/// will stop right after creating the diff; if there are locally-modified files
/// _in_ `docs/api/`, then they'll be erased during the 'checkout' step.
class InPlaceBranchUpdate extends BranchUpdate {
  /// A new [BranchUpdate] that doesn't use a temporary directory.
  InPlaceBranchUpdate(GitCommands git) : super(git, logTag: 'GH Pages');

  /// Absolute path to the patch created by [patchOutOfGitDiff].
  ///
  /// Used by [run].
  late String _patch;
  /// The name of the branch of [git] that was active when [run] was called.
  ///
  /// Used by [run] and [showOnCompleted].
  late String _startingBranchName;
  /// The SHA of the commit that was active (at **HEAD**) when [run] was called.
  ///
  /// Used by [run].
  late String _startingBranchSha;

  /// The directory where generated docs will be placed.
  ///
  /// Points to 'docs/api/' by default.
  final Directory outputDirectory = Directory(path.absolute('docs', 'api'));

  @override
  Future<void> showOnCompleted(Directory output) async {
    await super.showOnCompleted(output);
    logStatus(
      '''
The patch file used should still be around, in any case, if you want (or need)
to reapply it:

`git am ${_patch.trim()}`

When you're done, run one of the following to return your original branch:

`git switch -`
# or
`git checkout -`
# or
`git checkout $_startingBranchName`

''',
    );
    return Future.value();
  }

  @override
  Future<void> run(String branchName, List<String> arguments) async {
    logStatus('Found the git directory.');
    // Task 1: Save current state, in case something goes wrong.
    await _captureInitialState();
    // Task 2: Generate a documentation patch
    // TODO(Cliabhach): Pass branchName in, use fields for other params (?)
    _patch = await generateDocsPatch(git, outputDirectory, arguments,);
    // Task 3: Switch branch
    await checkoutGitHubBranch(git);
    // Task 4: Apply patch as a commit
    await git.applyPatch(_patch);
    // Task 5: Print instructions
    await showOnCompleted(outputDirectory);
  }

  Future<void> _captureInitialState() async {
    await git.stash();
    _startingBranchSha = await git.branchSha();
    _startingBranchName = await git.branchName();
    return Future.value();
  }

  /// Create a patch-file with updates to published documentation.
  ///
  /// Make sure [outputDirectory] points to the directory where only generated
  /// documentation files are located - the [generateAndWaitForDocs] call is
  /// allowed to overwrite anything in there.
  Future<String> generateDocsPatch(GitCommands git, Directory outputDirectory,
      List<String> arguments) async {
    // Task 1: Pull version number
    final versionString = await defineVersion();
    // Task 2: Prime the git index with files from the gh-pages branch
    await checkoutGitHubBranch(git, paths: [outputDirectory.path]);
    logStatus('Checked out files from gh-pages into ${outputDirectory.path}.');
    // Task 3: Generate docs into [outputDirectory]
    final generateFuture = generate(outputDirectory, arguments);
    logStatus('Started generating documentation...');
    // Task 4: Wait for existing work to complete
    await generateFuture;
    logStatus('...there, documentation generated!');
    // Task 5: Save our changes into a patch (this creates 2 temp commits)
    final patch = await patchOutOfGitDiff(
      git,
      outputDirectory.path,
      'docs: Regenerate to reflect $versionString',
    );
    // Task 6: Reset branch back to original state
    if (patch.isEmpty) {
      throw UnsupportedError("Patch wasn't generated correctly. Stopping now.");
    }
    await git.hardReset(_startingBranchSha);
    return patch;
  }
}
