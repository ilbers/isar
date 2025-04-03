# Contributing to Isar

Contributions to Isar are always welcome. This document explains general
requirements on contributions and recommended preparation steps. It also
sketches the typical patch integration process.

Improving Isar is not limited to development, it may also be:

* Testing

* Reviewing code

* Creating or improving documentation

* Helping with bugs (report, confirm the existence, find a way to reproduce,
  ...)

* Participating in technical discussions

All technical communication about Isar should take place on `isar-users`
mailing list. Please be polite and respect opinions and contributions of
others.

## Trunk based development guidelines

We adapt trunk based development technique

* `master` is the main development branch and not a stable release.

* `next` is a branch for CI (Continous Integration), testing and early feedback.

* `next` is sync'ed with `master` once in about two weeks (or more often whenever appropriate).

If a major problem exists in `master`, it will be handled with priority.
If a major change has been recently merged into `next`,  allow time to collect feedback and resolve issues.
Plan merges to `master` so that both fit the two-week window; short extensions should be an exception.

## Development

1. For bugs, we highly appreciate creating issues on GitHub as early as
   possible. This helps us to understand the problem when we see the patches
   and ensures the motivation for the changes is documented.

   Please provide at least the following information:

   * Problem description.

   * Expected / desired behavior.

   * Actual behavior.

   * How to reproduce.

   Please create one issue per bug; issues with multiple bugs are difficult to
   close.

   If you have a fix, send patches to `isar-users` mailing list. Providing the
   link to the latest series version in the Google Groups archive as a comment
   in the GitHub issue is appreciated. This helps us to review your patches
   more quickly and ensures that they are not overlooked. If you resend
   patches, please clearly mark them as v2, v3, ... in the cover letter
   subject.

2. Similarly, discussions about new features on the mailing list before
   starting development are highly appreciated. The following information is
   very helpful and should be provided along with the implementation at latest
   (earlier is welcome):

   * Functional description: What the change does.

   * Design: How the feature is implemented. What should be modified in the
     existing system, what should be added, etc.

3. Test your code.

   * No regressions are introduced in the affected code.

   * Seemingly unaffected boards still build.

   * It's highly suggested to test your patchset before submitting it to the mailing
     by launching CI tests scripts. The procedure is described below:

    ```
    git clone https://github.com/siemens/kas
    cat > kas.yml <<EOF
    header:
      version: 14
    build_system: isar
    defaults:
      repos:
        patches:
          repo: isar
    repos:
      isar:
        url: "http://github.com:/ilbers/isar"
        branch: next
        layers:
          meta:
          meta-isar:
    EOF
    kas/kas-container shell --command /work/isar/scripts/ci_setup.sh kas.yml
    ```

    In kas shell:

    ```
    cd /work/isar/testsuite
    avocado run citest.py -t dev --max-parallel-tasks=1
    ```

    Your git-formatpatches may be listed in the `kas.yml` file as illustrated below:

    ```
    ...
    repos:
      isar:
        url: "http://github.com:/ilbers/isar"
        branch: next
	patches:
          0001:
            path: /work/0001-my-contribution-to-isar.patch
        layers:
          meta:
          meta-isar:
    ```

    Perform the above steps from a clean directory for your CI run to be as close as
    possible to the environment that our project maintainers will be using. That
    directory would contain: *.patch isar/ kas/ kas.yml

    Be also mindful of community-provided resources such as deb.debian.org or
    snapshot.debian.org and consider using a caching proxy in your setup to
    reduce traffic as much as possible.

    Active developers may request from maintainers an account on isar-build.org
    to analyze CI logs or to launch their own CI builds there.

4. Structure patches logically, in small increments.

   * One separable fix / improvement / addition - one patch. Do not provide
     several of them in a single patch.

   * After every patch, the tree still has to build and work. Do not add even
     temporary breakages inside a patch series. This helps when tracking down
     bugs (`git bisect`).

   * Use `git rebase -i` to restructure patch series.

   * Do not mix semantically substantial changes with "empty" ones in a single
     patch. Semantically empty changes do not change the program logic. They
     are usually wide or mechanical, for example:

     * White space fixes

     * Coding style updates

     * Character set / encoding scheme changes

     Adding documentation for a feature or updating a copyright year is
     substantial and should be done together with the functional change (in the
     same patch or series).

   * Similarly, do not move and modify in one step. This applies both to moving
     larger chunks of code and file renaming. Move in one commit, modify in
     another. In this way, one can read `git log --patch` much faster.

     If not done, one sees deletions followed by additions elsewhere; this is
     problematic even for relatively small changes due to the following
     reasons:

     * The relationship between the hunks may not be immediately obvious.

     * Checking the difference requires careful line-by-line comparsion.

     `--follow` does show the diff after renaming, but can do that only for one
     explicitly specified file.

5. Actually read your patches.


## Formatting Patches

1. Isar uses Git version control system. Patches should be prepared in plain
   text format acceptable by `git am`.

   The easiest way to achieve that is to use Git.

   * Generate patches with `git format-patch` / `git send-email`.

   * Use `git diff --check` to get warned about whitespace errors.

2. Every patch should provide the following information:

   * Which part of Isar is affected.

   * Modification description:

     * For bug fixes: Describe what was broken, who was affected and how the
       patch fixes the problem.

     * For improvement: Describe in which way the current implementation is not
       optimal and how the patch improves the situation.

     * For new features: Describe the new functionality added by the patch and
       which feature requires it.

   * Reference to the GitHub issue (if applicable).

   * Add Signed-off-by to all patches.

     * To certify the "Developer's Certificate of Origin" according to "Sign
       your work" in
       https://www.kernel.org/doc/Documentation/process/submitting-patches.rst.

     * Check with your employer when not working on your own.

   * Base patches on top of the latest 'next' branch

   * Every file should carry the copyright and licensing information:

     Copyright (C) Year Holder

     Released under the MIT license (see meta/licenses/COPYING.MIT)

3. Every patch should implement only one logical modification. The patch
   granularity is up to the developer. In general, smaller patches with clear
   description are easier to review and accept.

4. Please provide patches that logically belong together in a series. And
   vice-versa, please do not submit unrelated patches as series.

   Every series should have a cover letter with brief information about:

   * What this series does.

   * How it was tested.

   * Diffstat (`git format-patch --cover-letter` does this for you).


## Contribution Process

1. Patches are reviewed on the mailing list.

   * At least by maintainers, but everyone is invited, so the process can be
     recurrent.

   * Feedback has to consider design, functionality and style.

   * Simpler and clearer code is preferred, even if the original code works
     fine.

2. After the review, patches are applied to the maintainers testing branch and
   CI checks are executed.

3. If CI tests are passed OK and no new comments have appeared,
   the patches are merged into the `next` branch and later (normally in two weeks)
   into `master`.


GitHub facilities other than issues are not used for the review process, so
that people can follow all changes and related discussions at one stop, the
mailing list. This may change in the future.


## Contacts

1. Maintainers:

   * Maxim Yu. Osipov <mosipov@ilbers.de>

   * Baurzhan Ismagulov <ibr@ilbers.de>

2. Mail list:

   * `isar-users@googlegroups.com`
