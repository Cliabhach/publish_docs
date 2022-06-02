// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/branch_update.dart';
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
/// This implementation is for repositories who choose to point it at 'docs/'.
/// It will generate files into that directory on top of whatever commit is
/// currently checked out, and then use some git commands to attach the new
/// files to your dedicated GitHub Pages branch. See [run] for more details.
///
/// # How?
///
/// Rough overview of git commands:
///
/// ```bash
/// git checkout $branch docs/api
/// #(we generate the docs at this point)
/// git diff > localfile.patch
/// git reset --hard HEAD
/// git checkout $branch
/// git am localfile.patch
/// ```
///
/// # Additional notes
///
/// If there are locally-modified files in the repo then we will save them into
/// a stash right before creating the diff; if there are files in `docs/api/`
/// which are only defined on the _original_ branch, then they'll be erased
/// during the 'checkout' step.
///
/// This means **try not to modify the project, _especially the git status_,
/// while this update is [run]ning**.
class InPlaceBranchUpdate extends BranchUpdate {
  /// A new [BranchUpdate] that doesn't use a temporary directory.
  ///
  /// Call [run] to start the update.
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

  /// Make the update using this function!
  ///
  /// This essentially [generates some docs][generateDocsPatch], and _then_
  /// creates a patch representing what's changed. We can apply that [_patch] on
  /// top of the branch called [branchName] to create a straightforward commit -
  /// and if all goes well we do just that.
  ///
  /// The class docs for [InPlaceBranchUpdate] cover the larger question of
  /// _why_, and inline comments cover the smaller details of _how_.
  ///
  /// See also [generate] and [doFormatPatch].
  @override
  Future<void> run(String branchName, List<String> arguments) async {
    logStatus('Found the git directory.');
    // Task 1: Save current state, in case something goes wrong.
    await _captureInitialState();
    // Task 2: Generate a documentation patch
    _patch = await generateDocsPatch(branchName, arguments,);
    // Task 3: Switch branch
    await git.checkoutBranch(branchName);
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
  /// This method tries to use docs from an existing branch as a basis for the
  /// patch. Provide the [name] of that branch as a parameter.
  ///
  /// Make sure [outputDirectory] points to the directory where only generated
  /// documentation files are located - the [generate] call is allowed to
  /// overwrite anything in there.
  Future<String> generateDocsPatch(String name, List<String> arguments) async {
    // Task 1: Pull version number
    final versionString = await defineVersion();
    // Task 2: Prime the git index with files from the given branch
    await git.checkoutBranch(name, paths: [outputDirectory.path]);
    logStatus('Checked out files from $name into ${outputDirectory.path}.');
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
