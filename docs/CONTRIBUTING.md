# Contributing Guide

Welcome! We love receiving contributions from the community, so thanks for stopping by! There are many ways to contribute, including submitting bug reports, improving documentation, submitting feature requests, reviewing new submissions, or contributing code that can be incorporated into the project.

This document describes the Embedded Artistry development process. Following these guidelines shows that you respect the time and effort of the developers managing this project. In return, you will be shown respect in addressing your issue, reviewing your changes, and incorporating your contributions.

**Table of Contents:**

1. [Code of Conduct](#code-of-conduct)
2. [Important Resources](#important-resources)
2. [Questions](#questions)
3. [Feature Requests](#feature-requests)
4. [Improving Documentation](#improving-documentation)
5. [Reporting Bugs](#reporting-bugs)
6. [Contributing Code](#contributing-code)
	1. [Getting Started](#getting-started)
	1. [Development Process](#development-process)
	1. [Building the Project](#building-the-project)
	1. [Style Guidelines](#style-guidelines)
	1. [Whitespace Cleanup](#whitespace-cleanup)
1. [Pull Request Guidelines](#pull-request-process)
	1. [Review Process](#review-process)
	1. [Addressing Feedback](#addressing-feedback)


## Code of Conduct

By participating in this project, you agree to abide by the Embedded Artistry [Code of Conduct][0]. We expect all contributors to follow the [Code of Conduct][0] and to treat fellow humans with respect.

## Important Resources

This project is managed on GitHub:

* [GitHub Project Page](https://github.com/embeddedartistry/libcpp)
* [GitHub Issue Tracker](https://github.com/embeddedartistry/libcpp/issues

## Questions

Please submit your questions in the following ways:

* Filing a new [GitHub Issue](https://github.com/embeddedartistry/libcpp/issues)
* [Joining the Embedded Artistry Slack team](https://join.slack.com/t/embeddedartistry/shared_invite/enQtMjgyNzI2MDY4NjkyLTcyZTk2OGZjZTk2MGY3NzMyNGM4NDg0ZjYyNzEyNDI1MzA1ZjYzNTc2Y2EzMzM5N2IyZmViYWFhMGRjZDM3Zjk)
* [Submitting a question on the Embedded Artistry website](https://embeddedartistry.com/contact)
* Asking a question on Twitter: [\@mbeddedartistry](https://twitter.com/mbeddedartistry/).

## Feature Requests

We welcome feature requests!

For all requests, [please file a new GitHub issue](https://github.com/embeddedartistry/libcpp/issues). Please provide the details about the feature/function you would like to see and why you need it. Please discuss your ideas and feedback before proceeding.

Small Changes can directly be crafted and submitted to the GitHub Repository as a Pull Request. See the section regarding [Pull Request Submission Guidelines](#pull-request-guidelines).

## Reporting Bugs

Before you submit your issue, please [search the issue archive](https://github.com/embeddedartistry/libcpp/issues) - maybe your question or issue has already been identified or addressed.

If you find a bug in the source code, you can help us by [submitting an issue to our GitHub issue tracker](https://github.com/embeddedartistry/libcpp/issues). Even better, you can submit a Pull Request with a fix!

This project uses an [issue template](ISSUE_TEMPLATE.md), which GitHub will auto-populate when you create a new issue. Please make sure to follow the template and provide the necessary information. This will help us track down the bug as quickly as possible.

## Contributing Code

Working on your first open source project or pull request? Here are some helpful tutorials:

* [How to Contribute to an Open Source Project on GitHub][2]
* [Make a Pull Request][3]
* [First Timers Only][4]

### Getting Started

Install these dependencies:

* [Meson](#meson-build-system) is the build system
* [`git-lfs`](https://git-lfs.github.com) is used to store binary files
* `make` is required to use Makefile shims
* A compiler should be installed in order to build the project (gcc + clang have been tested)

You will need to fork the main repository to work on your changes. Simply navigate to our GitHub page and click the "Fork" button at the top. Once you've forked the repository, you can clone your new repository and start making edits.

When using `git`, it is best to isolate each topic or feature into a “topic branch”. Branches are a great way to group commits related to one feature together, or to isolate different efforts when you might be working on multiple topics at the same time.

While it takes some experience to get the right feel about how to break up commits, a topic branch should be limited in scope to a single issue. If you are working on multiple issues, please create multiple branches and submit them for review separately.

```
# Checkout the master branch - you want your new branch to come from master
git checkout master

# Create a new branch named newfeature (give your branch its own simple informative name)
git branch newfeature

# Switch to your new branch
git checkout newfeature
```

For more information on the GitHub fork and pull-request processes, [please see this helpful guide][5].

### Development Process

`master` contains the latest code, and new versions are tagged nightly.

Please branch from `master` for any new changes. Once you are ready to merge changes, open a pull request. The build server will test and analyze the branch to ensure it can be safely merged.

### Building the Project

To run the build, simply call:

```
$ make
```

This will build the library. You can build individual projects by navigating to `buildresults` and using the `ninja` interface.

#### Cross-compiling

Cross-compilation is handled using `meson` cross files. Example files are included in the [`build/cross`](build/cross/) folder. You can write your own cross files for your specific platform (or open an issue and we can help you).

Cross-compilation must be configured using the meson command when creating the build output folder. For example:

```
meson buildresults --cross-file build/cross/gcc/arm/gcc_arm_cortex-m4.txt
```

Following that, you can run `make` (at the project root) or `ninja` (within the build output directory) to build the project.

### Style Guidelines

This project does not currently have an explicit style guideline, since it is primarily a build system wrapper for another project.

### Whitespace Cleanup

Don’t mix code changes with whitespace cleanup! If you are fixing whitespace, include those changes separately from your code changes. If your request is unreadable due to whitespace changes, it will be rejected.

Please submit any whitespace cleanups in a separate pull request.

### Git Commit Guidelines

The first line of the commit log must be treated as as an email subject line.  It must be strictly no greater than 50 characters long. The subject must stand on its own and not only make external references such as to relevant bug numbers.

The second line must be blank.

The third line begins the body of the commit message (one or more paragraphs) describing the details of the commit.  Paragraphs are each separated by a blank line. Manual line breaks are not required.

The last part of the commit log should contain all "external references", such as which issues were fixed.

For further notes about git commit messages, [please read this blog post][7].

## Pull Request Process

When you are ready to generate a pull request for preliminary review or merging into the project, you must first push your local topic branch back up to GitHub:

```
git push origin newfeature
```

Once you've committed and pushed all of your changes to GitHub:
    * Go to the page for your fork on GitHub
    * Select your development branch
    * Click the pull request button

If you need to make any adjustments to your pull request, just push the updates to your branch. Your pull request will automatically track the changes on your development branch and update.

Please follow the [Pull Request Template](PULL_REQUEST_TEMPLATE.md) for this project. GitHub will automatically populate the pull request description with this template.

### Review Process

Changes must build correctly on the Jenkins CI server, be free of formatting errors, and pass tests.

One the changes pass the CI process, I will review the source code and provide feedback. I work on a variety of projects, so please expect some delay in getting back to you with a code review. I will notify you as soon as I have seen the PR and provide insight into the expected review timeline.

### Addressing Feedback

Once a PR has been submitted, your changes will be reviewed and constructive feedback may be provided. Feedback isn't meant as an attack, but to help make sure the highest-quality code makes it into our project. Changes will be approved once required feedback has been addressed.

If a maintainer asks you to "rebase" your PR, they're saying that a lot of code has changed, and that you need to update your fork so it's easier to merge.

To update your forked repository, follow these steps:

```
# Fetch upstream master and merge with your repo's master branch
git fetch upstream
git checkout master
git merge upstream/master

# If there were any new commits, rebase your development branch
git checkout newfeature
git rebase master
```

If too much code has changed for git to automatically apply your branches changes to the new `master`, you will need to manually resolve the merge conflicts yourself.

Once your new branch has no conflicts and works correctly, you can override your old branch using this command:

```
git push -f
```

Note that this will overwrite the old branch on the server, so make sure you are happy with your changes first!

**If you have any questions about this process, please ask for help!**

## Community

Anyone interested in active conversation regarding this project should [join the Embedded Artistry Slack team]https://join.slack.com/t/embeddedartistry/shared_invite/enQtMjgyNzI2MDY4NjkyLTcyZTk2OGZjZTk2MGY3NzMyNGM4NDg0ZjYyNzEyNDI1MzA1ZjYzNTc2Y2EzMzM5N2IyZmViYWFhMGRjZDM3Zjk)).

You can also reach out on Twitter: [\@mbeddedartistry](https://twitter.com/mbeddedartistry/).

[0]: CODE_OF_CONDUCT.md
[1]: style_guidelines.md
[2]: https://egghead.io/series/how-to-contribute-to-an-open-source-project-on-github
[3]: http://makeapullrequest.com/
[4]: http://www.firsttimersonly.com
[5]: https://gist.github.com/Chaser324/ce0505fbed06b947d962
[6]: link/to/your/project/issue/tracker
[7]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
