# <img src="./logo.svg" height="32px" /> Rainforest QA GitHub Action ![](https://img.shields.io/github/v/release/rainforestapp/github-action.svg)

**Marketplace homepage:** [`rainforestapp/github-action`](https://github.com/marketplace/actions/rainforest-qa-github-action)

> This is the Rainforest QA [GitHub Action](https://docs.github.com/en/actions), it allows you to easily kick off a Rainforest run from your GitHub workflows, to make sure that every release passes your Rainforest integration tests.

## Sections
* [Prerequisites](#prerequisites)
* [Base Usage](#base-usage)
* [Optional Parameters](#optional-parameters)
* [Release Process](#github-action-release-process)

## Prerequisites

### A Rainforest QA account

If you don't already have one, you can sign up for a free account [here](https://app.rainforestqa.com/auth/signup?utm_source=github&utm_medium=readme&utm_campaign=ghaction).

### A Rainforest QA API token

You can find yours on the [Integrations](https://app.rainforestqa.com/settings/integrations) setting page.
Do not expose this token in your `.github/workflows/<workflow>.yml` file. Instead, [use a GitHub encrypted secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets). You may name this secret as you wish (as long as it's a name allowed by GitHub), e.g. `RAINFOREST_API_TOKEN`.

### A run group with at least one test

Run groups are a way to group tests that should be run together (for example, a smoke suite you might want to run on every deploy). For more information on run groups, see [this help article](https://help.rainforestqa.com/docs/organizing-tests-by-run-group).

Once you have a run group which contains at least one enabled test, you can run it in GitHub workflows using this Action. You will need its ID (visible at the end of the run group URL: `https://app.rainforestqa.com/run_groups/<ID>`).

## Base usage
This is a simple workflow file that will start a Rainforest run using run group #1234 every time a commit is pushed to the `main` branch. To use it, change the run group ID to the one you wish to run, ensure your Rainforest API token is properly configured in your GitHub secrets, and commit this file in your repo at `.github/workflows/rainforest.yml`.

```yaml
on:
  push:
    branches:
      - main

jobs:
  rainforest:
    runs-on: ubuntu-latest
    name: Run Rainforest
    steps:
      - name: Rainforest
        uses: rainforestapp/github-action@master
        with:
          token: ${{ secrets.RAINFOREST_API_TOKEN }}
          run_group_id: 1234
```

## Optional Parameters

### `description`
An arbitrary string to associate with the run.
#### Default behavior
The default value :
> `"${GITHUB_REPOSITORY} - ${GITHUB_REF_NAME} ${GITHUB_JOB} $(date -u +'%FT%TZ')"`

This means that if no `description` parameter is passed in and your repository is named `my_org/my_repo`, the GitHub job is `#42` on the `my_feature_branch` branch, and the current time (in UTC) is noon on December 31st, 2021; then the created run's description will be:
> `my_org/my_repo - my_feature_branch 42 2021-12-31T12:00:00Z`

### `environment_id`
Use a specific environment for this run. _This parameter will be ignored if the `custom_url` parameter is also passed in._
#### Default behavior
If no `environment_id` parameter is passed in, the created run will use the Run Group's default environment.

### `custom_url`
Use a specific URL (via a [temporary environment](https://github.com/rainforestapp/rainforest-cli#command-line-options)) for this run.
#### Default behavior
If no `custom_url` parameter is passed in, the created run will use the Run Group's default environment.

### `conflict`
How we should handle currently active runs.
#### Allowed values
Value | Behavior
--- | ---
`cancel` | Cancel all other runs in the same environment.
`cancel-all` | Cancel all other runs, regardless of environment.
#### Default behavior
If no `conflict` parameter is passed in, then no active runs will be canceled.

### `execution_method`
The execution method to use for this run.
#### Allowed values
Value | Behavior | Requirements
--- | --- | ---
`automation` | Run against our automation agent. | - All tests in the run group are written with the Visual Editor.<br />- No tests use a Tester Instruction/Confirmation action.
`crowd` | Run against our global crowd of testers.
`automation_and_crowd` | Run against our automation agent where possible, fall back to the crowd of testers.
`on_premise` | Run against your internal testers. | - On-premise is enabled for your account.
#### Default behavior
If no `execution_parameter` parameter is passed in, the created run will run against the run group's default execution method.

### `release`
A string used to link a run to a release (for example, a `git` SHA or tag, a version number, a code name)
#### Default behavior
If no `release` parameter is passed in, the SHA1 hash of the latest commit of the current workflow (obtained via the `GITHUB_SHA` environment variable) will be used.

### `automation_max_retries`
Set to a value larger than `0` to retry failed tests excuted by our automation agent in the same run up to that number of times.
#### Default behavior
If no `automation_max_retries` parameter is passed in, the [default from your account or run group is used](https://help.rainforestqa.com/docs/test-retries).

### `branch`
Use a specific Rainforest branch for this run.
#### Default behavior
If no `branch` parameter is passed in, the `main` branch will be used.

### `background`
Set to `true` to immediately complete the GitHub workflow job without waiting for the Rainforest run to complete
### Default behavior
By default we wait for the run to complete in order to pass or fail the workflow job based on the run's result.

### `dry_run`
Set to `true` to run parameter validations without actually starting a run in Rainforest.
#### Default behavior
If no `dry_run` parameter is passed in, the run will be started in Rainforest.

## Rerunning failed tests
If your Rainforest run fails due to a ["non-bug"](https://rainforest.engineering/2021-01-20-shipping-faster-orb/) (your testing environment might have had a hiccup, or a test might have needed to be tweaked, etc), then rather than make code changes and then run your full testing suite once more, you'll instead want to rerun just the tests that failed. The Rainforest QA GitHub Action uses GitHub [caching](https://docs.github.com/en/actions/advanced-guides/caching-dependencies-to-speed-up-workflows) to know when a workflow is [being rerun](https://docs.github.com/en/actions/managing-workflow-runs/re-running-workflows-and-jobs). It will then automatically rerun only the tests which failed in the previous run.

## GitHub Action Release Process
This section describes the release process for the Action itself:
1. Create a feature branch and do your work.
1. Update the version in `action.yml`.
1. Get review and merge to master.
1. Create a [GitHub Release](https://github.com/rainforestapp/github-action/releases/new) with the proper `v`-prefixed version tag (i.e. `v0.0.1`). List **Bugfixes**, **Breaking changes**, and **New features** (if present), with links to the PRs. See [previous releases](https://github.com/rainforestapp/github-action/releases) for an idea of the format we're using.
1. The `release.yml` workflow will then run to update the major release tag. E.g. if your release was for `v1.2.3`, then it will automatically update the `v1` tag.

If you want to run an integration test, create a new branch in a repo of your choice and add a new workflow to`.github/workflows/` with the action pointing to your commit.
