// SPDX-License-Identifier: BSD-3-Clause

/// An abstraction over [Git](https://git-scm.com/).
///
abstract class GitCommands {

  /// Add the content of one or more files to the git staging index.
  ///
  /// The `.git` directory contains references to every file in every commit.
  /// Before attaching a file to a [commit], you must add the contents of that
  /// file to the staging index with this command.
  ///
  /// Inverse: [reset]
  void add();

  /// Apply a git patch to the git staging index, and then commit that patch.
  ///
  /// This `apply mailbox` command is the thing to use when you want to move
  /// commits from one repository history to another.
  ///
  /// To be used along-side [formatPatch].
  void am();

  /// Change the contents of one or more files to match those in a given commit.
  ///
  /// By itself this command does not modify the git staging index. To remove
  /// files from _that_, use [reset].
  void checkout();

  /// Record the git staging index in the regular git index.
  ///
  /// This is (arguably) the most important command, and the key to saving your
  /// in-progress work.
  ///
  /// Inverse: [reset] (with the 'hard' flag)
  void commit();

  /// Create one or more patches that can be used later to recreate commits.
  ///
  /// This is the recommended way to copy commits from one repository history
  /// to another repository history.
  ///
  /// To be used along-side [am].
  void formatPatch();

  /// Get basic information from a git repository.
  ///
  /// This is sort of a utility method, that can check whether certain things
  /// are true about this repository. We use it mainly to translate between
  /// 'refs' (like **HEAD** or 'main') and commit hashes.
  void revParse();

  /// Remove one or more files from the git staging index.
  ///
  /// Pass along the 'hard' flag to remove commits from the regular git index.
  ///
  /// Inverse: [add]
  void reset();

  /// Create or remove a 'stash' commit.
  ///
  /// This command can be used as an alternative to [commit] and [reset] to
  /// save in-progress work. When you call this, git will create a new commit
  /// with the reference `stash{0}` with the contents of the git staging index,
  /// but it will _not_ point to that new reference. Very useful for putting
  /// someone else's work aside while you get your own work done.
  ///
  /// Inverse: [stash] (with the 'pop' flag)
  void stash();
}
