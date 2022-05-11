// SPDX-License-Identifier: BSD-3-Clause

/// An abstraction over [Git](https://git-scm.com/).
///
/// There is one implementation in `GitDirCommands`.
abstract class GitCommands {

  /// Create a new [GitCommands] abstraction.
  ///
  /// The 'path' property must be defined at this point.
  GitCommands(this.path);

  /// Return an absolute path to the root of this git repository.
  ///
  /// Implementors must provide this to the constructor.
  final String path;

  /// Add the content of one or more files to the git staging index.
  ///
  /// The `.git` directory contains references to every file in every commit.
  /// Before attaching a file to a [commit], you must add the contents of that
  /// file to the staging index with this command.
  ///
  /// Inverse: [reset]
  Future<void> add(String path);

  /// Apply a git patch to the git staging index, and then commit that patch.
  ///
  /// This `apply mailbox` command is the thing to use when you want to move
  /// commits from one repository history to another.
  ///
  /// To be used along-side [formatPatch].
  Future<void> am(String patchFilePath);

  /// Retrieve the name of the current branch.
  ///
  /// Equivalent to `git symbolic-ref HEAD`.
  Future<String> branchName();

  /// Retrieve the SHA-1 hash for the current tip of a git branch.
  ///
  /// Note that this hash will change if a [commit] is added to the branch, or
  /// if it is [reset] to a specific hash.
  ///
  /// By default, we request the SHA-1 hash of the current branch.
  Future<String> branchSha({String name = 'HEAD'});

  /// Change the contents of one or more files to match those in a given commit.
  ///
  /// By itself this command does not modify the git staging index. To remove
  /// files from _that_, use [reset].
  Future<void> checkout(String gitRef, {List<String> paths = const []});

  /// Record the git staging index in the regular git index.
  ///
  /// This is (arguably) the most important command, and the key to saving your
  /// in-progress work.
  ///
  /// Inverse: [reset] (with the 'hard' flag)
  Future<void> commit(String message);

  /// Retrieve the git history from the current **HEAD**.
  ///
  /// This is the same sort of output you see when running `git log`, but with
  /// much fewer details. The first String is the SHA-1 hash of the **HEAD**
  /// commit, the second is the SHA-1 hash of the parent commit of that
  /// **HEAD**, the third is the SHA-1 hash of the parent of the second commit,
  /// and so on up until the root commit.
  ///
  /// If there are multiple parents for one commit in the sequence...that's
  /// probably fine.
  Future<Iterable<String>> get commits;

  /// Create one or more patches that can be used later to recreate commits.
  ///
  /// This is the recommended way to copy commits from one repository history
  /// to another repository history.
  ///
  /// To be used along-side [am].
  Future<String> formatPatch(String gitStartRef, String gitEndRef);

  /// Get basic information from a git repository.
  ///
  /// This is sort of a utility method, that can check whether certain things
  /// are true about this repository. We use it mainly to translate between
  /// 'refs' (like **HEAD** or `origin/main`) and commit hashes.
  Future<String> revParse(Iterable<String> args);

  /// Remove one or more files from the git staging index.
  ///
  /// Pass along the 'hard' flag to remove commits from the regular git index.
  ///
  /// Inverse: [add]
  Future<void> reset(String gitRef, {bool hard});

  /// Create or remove a 'stash' commit.
  ///
  /// This command can be used as an alternative to [commit] and [reset] to
  /// save in-progress work. When you call this, git will create a new commit
  /// with the reference `stash{0}` with the contents of the git staging index,
  /// but it will _not_ point to that new reference. Very useful for putting
  /// someone else's work aside while you get your own work done.
  ///
  /// Inverse: [stash] (with the 'pop' flag)
  Future<void> stash();
}
