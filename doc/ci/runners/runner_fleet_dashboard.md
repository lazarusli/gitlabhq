---
stage: Verify
group: Runner
info: >-
  To determine the technical writer assigned to the Stage/Group associated with
  this page, see
  https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
# Runner Fleet Dashboard **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/424495) in GitLab 16.6

GitLab administrators can use the Runner Fleet Dashboard to assess the health of your instance runners.
The Runner Fleet Dashboard shows:

- Recent CI errors related caused by runner infrastructure.
- Number of concurrent jobs executed on most busy runners.
- Histogram of job queue times [(available only with ClickHouse)](#enable-more-ci-analytics-features-with-clickhouse).

Support for usage and cost analysis are proposed in [epic 11183](https://gitlab.com/groups/gitlab-org/-/epics/11183).

![Runner Fleet Dashboard](img/runner_fleet_dashboard.png)

## View the Runner Fleet Dashboard

Prerequisites:

- You must be an administrator.

To view the runner fleet dashboard:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Runners**.
1. Click **Fleet dashboard**.

Most of the dashboard works without any additional actions, with the
exception of **Wait time to pick a job** chart and features proposed in [epic 11183](https://gitlab.com/groups/gitlab-org/-/epics/11183).
These features require [setting up an additional infrastructure](#enable-more-ci-analytics-features-with-clickhouse).

## Enable more CI analytics features with ClickHouse **(ULTIMATE EXPERIMENT)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11180) in GitLab 16.7 behind several [feature flags](#enable-clickhouse-integration-and-features).

This feature is an [Experiment](../../policy/experiment-beta-support.md).
To test it, we have launched an early adopters program.
To join the list of users testing this feature, see
[epic 11180](https://gitlab.com/groups/gitlab-org/-/epics/11180).

### Enable ClickHouse integration and features

To enable additional CI analytics features:

1. [Configure ClickHouse integration](../../integration/clickhouse.md)
1. [Enable](../../administration/feature_flags.md#how-to-enable-and-disable-features-behind-flags) the following feature flags:

   | Feature flag name                  | Purpose                                                                   |
   |------------------------------------|---------------------------------------------------------------------------|
   | `ci_data_ingestion_to_click_house` | Enables synchronization of new finished CI builds to ClickHouse database. |
   | `clickhouse_ci_analytics`          | Enables the **Wait time to pick a job** chart.                            |

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video walkthrough, see [Setting up Runner Fleet Dashboard with ClickHouse](https://www.youtube.com/watch?v=YpGV95Ctbpk).

## Feedback

To help us improve the Runner Fleet Dashboard, you can provide feedback in
[issue 421737](https://gitlab.com/gitlab-org/gitlab/-/issues/421737).
In particular:

- How easy or difficult it was to setup GitLab to make the dashboard work.
- How useful you found the dashboard.
- What other information you would like to see on that dashboard.
- Any other related thoughts and ideas.
