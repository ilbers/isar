# Introduction

Isar maintainer is the person who keeps the project development in
compliance with the contributing process definition. The purpose of
this document is to describe the maintainer process in the Isar
project.

# Responsibilities

## Feedback on Contributions

The Isar maintainer should review each contribution that has been sent
to the mailing list and provide feedback. The feedback could be on the
following categories:

 - Contribution accepted: If no quality and design issues were found
   by the maintainer and the other mailing list members.

 - Change request: If some small quality or design issues were found,
   the maintainer or the other mailing list memeber requests a new
   version with resolved issues.

 - Contribution rejected: If there are major design issues or general
   benefit from the contribution is ambiguous.

During the review, the maintainer may ask additional questions to
clarify the details. Any other mailing list member could assist the
maintainer in the review process.

## Repository Branches

There are two official branches in Isar, intended to increase project
quality:

 - next: The accepted contributions from the mailing list are merged
   to this branch. Basic CI checks should be run after each merge.
   This branch could be changed non-linearly.

 - master: Is the official stable branch. The only way patches go in
   here is coming from 'next', where they have passed all required
   tests and undergone the review process. On this branch force-pushing
   will never be used.

The next branch is intended to be merged into master monthly. The
maintainer may perform a merge to master before the ordinary window
if the next branch contains urgent patch series (bug fixes or critical
features).

## Issues at GitHub

For each issue that has been found in master and next branches the
maintainer should create a GitHub issue. The issue should reflect to
the one of the following:
 - Bug in the existing Isar code.
 - New Isar feature that is planned to be developed.
 - Improvement that would be nice to have in Isar.
