// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/branch_update.dart';
import 'package:publish_docs/src/operation/gh_pages_patch.dart';
import 'package:publish_docs/src/util/git_util.dart';

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
/// We always try to return to the original branch state at the end of the
/// process. If there are locally-modified files outside of `docs/api/` then we
/// will stop right after creating the diff; if there are locally-modified files
/// _in_ `docs/api/`, then they'll be erased during the 'checkout' step.
@Deprecated('Please migrate to InPlaceBranchUpdate')
Future<void> updateGitHubPages(GitCommands git, List<String> arguments) async {
  // Task 0: Save current state, in case something goes wrong.
  final startingBranchSha = await git.branchSha();
  final startingBranchName = await git.branchName();
  await git.stash();
  logStatus('Found the git directory.');
  // Task 1: Define constants for use in this function
  final outputDirectory = Directory(path.absolute('docs', 'api'));
  // Task 2: Generate a documentation patch
  final patch = await generateDocsPatch(
    git,
    outputDirectory,
    arguments,
    startingBranchSha,
  );
  // Task 3: Switch branch
  await checkoutGitHubBranch(git);
  // Task 4: Apply patch as a commit
  await git.applyPatch(patch);
  // Task 5: Print instructions
  final indexDocFile =
      Directory(path.absolute(outputDirectory.path, 'index.html'));
  logStatus(
    '''
The gh-pages branch has been updated. Please review the files in docs/api/ to
make sure there aren't any surprises there. We recommend opening the index.html
(located at ${indexDocFile.uri} )
in the browser, at the very least. If it all looks good and there are no
conflicts with the remote, you can push the new pages to GitHub with a simple

`git push`

If there's a conflict, or there are other issues with the changes, you can
remove the new commit by calling

`git reset --hard HEAD~`

The patch file used should still be around, in any case, if you want (or need)
to reapply it:

`git am ${patch.trim()}`

When you're done, run one of the following to return your original branch:

`git switch -`
# or
`git checkout -`
# or
`git checkout $startingBranchName`

''',
  );
  // Task 6: Switch back
  // await git.checkoutBranch(startingBranchSha);
  //logStatus("We're back at the original branch now.");
}
