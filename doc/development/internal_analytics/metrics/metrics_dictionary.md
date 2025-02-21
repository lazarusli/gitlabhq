---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Metrics Dictionary Guide

[Service Ping](../service_ping/index.md) metrics are defined in individual YAML files definitions from which the
[Metrics Dictionary](https://metrics.gitlab.com/) is built. Currently, the metrics dictionary is built automatically once a day. When a change to a metric is made in a YAML file, you can see the change in the dictionary within 24 hours.
This guide describes the dictionary and how it's implemented.

## Metrics Definition and validation

We are using [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json) to validate the metrics definition.

This process is meant to ensure consistent and valid metrics defined for Service Ping. All metrics *must*:

- Comply with the defined [JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Have a unique `key_path` .
- Have an owner.

All metrics are stored in YAML files:

- [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics)

WARNING:
Only metrics with a metric definition YAML and whose status is not `removed` are added to the Service Ping JSON payload.

Each metric is defined in a separate YAML file consisting of a number of fields:

| Field               | Required | Additional information                                                                                                                                                                                                                                                                                                                |
|---------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `key_path`          | yes      | JSON key path for the metric, location in Service Ping payload.                                                                                                                                                                                                                                                                       |
| `description`       | yes      |                                                                                                                                                                                                                                                                                                                                       |
| `product_section`   | yes      | The [section](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/sections.yml).                                                                                                                                                                                                                                          |
| `product_stage`     | yes      | The [stage](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) for the metric.                                                                                                                                                                                                                                 |
| `product_group`     | yes      | The [group](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) that owns the metric.                                                                                                                                                                                                                           |
| `value_type`        | yes      | `string`; one of [`string`, `number`, `boolean`, `object`](https://json-schema.org/understanding-json-schema/reference/type.html).                                                                                                                                                                                                    |
| `status`            | yes      | `string`; [status](#metric-statuses) of the metric, may be set to `active`, `removed`, `broken`.                                                                                                                                                                                                                                      |
| `time_frame`        | yes      | `string`; may be set to a value like `7d`, `28d`, `all`, `none`.                                                                                                                                                                                                                                                                      |
| `data_source`       | yes      | `string`; may be set to a value like `database`, `redis`, `redis_hll`, `prometheus`, `system`, `license`, `internal_events`.                                                                                                                                                                                                          |
| `data_category`     | yes      | `string`; [categories](#data-category) of the metric, may be set to `operational`, `optional`, `subscription`, `standard`. The default value is `optional`.                                                                                                                                                                           |
| `instrumentation_class` | no       | `string`; used for metrics with `data_source` other than `internal_events`. See [the class that implements the metric](../service_ping/metrics_instrumentation.md).                                                                                                                                                                   |
| `distribution`      | yes      | `array`; may be set to one of `ce, ee` or `ee`. The [distribution](https://about.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available.                                                                                                 |
| `performance_indicator_type`  | no       | `array`; may be set to one of [`gmau`, `smau`, `paid_gmau`, `umau` or `customer_health_score`](https://about.gitlab.com/handbook/business-technology/data-team/data-catalog/xmau-analysis/).                                                                                                                                          |
| `tier`              | yes      | `array`; may contain one or a combination of `free`, `premium` or `ultimate`. The [tier](https://about.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available. This should be verbose and contain all tiers where a metric is available. |
| `milestone`         | yes      | The milestone when the metric is introduced and when it's available to self-managed instances with the official GitLab release.                                                                                                                                                                                                       |
| `milestone_removed` | no       | The milestone when the metric is removed. Required for removed metrics.                                                                                                                                                                                                                                                               |
| `introduced_by_url` | no       | The URL to the merge request that introduced the metric to be available for self-managed instances.                                                                                                                                                                                                                                   |
| `removed_by_url`    | no       | The URL to the merge request that removed the metric. Required for removed metrics.                                                                                                                                                                                                                                                   |
| `repair_issue_url`  | no       | The URL of the issue that was created to repair a metric with a `broken` status.                                                                                                                                                                                                                                                      |
| `options`           | no       | `object`: options information needed to calculate the metric value.                                                                                                                                                                                                                                                                   |

### Metric `key_path`

The `key_path` of the metric is the location in the JSON Service Ping payload.

The `key_path` could be composed from multiple parts separated by `.` and it must be unique.

We recommend to add the metric in one of the top-level keys:

- `settings`: for settings related metrics.
- `counts_weekly`: for counters that have data for the most recent 7 days.
- `counts_monthly`: for counters that have data for the most recent 28 days.
- `counts`: for counters that have data for all time.

### Metric statuses

Metric definitions can have one of the following statuses:

- `active`: Metric is used and reports data.
- `broken`: Metric reports broken data (for example, -1 fallback), or does not report data at all. A metric marked as `broken` must also have the `repair_issue_url` attribute.
- `removed`: Metric was removed, but it may appear in Service Ping payloads sent from instances running on older versions of GitLab.

### Metric `value_type`

Metric definitions can have one of the following values for `value_type`:

- `boolean`
- `number`
- `string`
- `object`: A metric with `value_type: object` must have `value_json_schema` with a link to the JSON schema for the object.
  In general, we avoid complex objects and prefer one of the `boolean`, `number`, or `string` value types.
  An example of a metric that uses `value_type: object` is `topology` (`/config/metrics/settings/20210323120839_topology.yml`),
  which has a related schema in `/config/metrics/objects_schemas/topology_schema.json`.

### Metric `time_frame`

A metric's time frame is calculated based on the `time_frame` field and the `data_source` of the metric.

| data_source            | time_frame | Description                                     |
|------------------------|------------|-------------------------------------------------|
| any                    | `none`     | A type of data that's not tracked over time, such as settings and configuration information |
| `database`             | `all`      | The whole time the metric has been active (all-time interval) |
| `database`             | `7d`       | 9 days ago to 2 days ago |
| `database`             | `28d`      | 30 days ago to 2 days ago |
| `internal_events`      | `all`      | The whole time the metric has been active (all-time interval) |
| `internal_events`      | `7d`       | Most recent complete week |
| `internal_events`      | `28d`      | Most recent 4 complete weeks |

### Data category

We use the following categories to classify a metric:

- `operational`: Required data for operational purposes.
- `optional`: Default value for a metric. Data that is optional to collect. This can be [enabled or disabled](../../../administration/settings/usage_statistics.md#enable-or-disable-service-ping) in the Admin Area.
- `subscription`: Data related to licensing.
- `standard`: Standard set of identifiers that are included when collecting data.

An aggregate metric is a metric that is the sum of two or more child metrics. Service Ping uses the data category of
the aggregate metric to determine whether or not the data is included in the reported Service Ping payload.

### Example YAML metric definition

The linked [`uuid`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/license/uuid.yml)
YAML file includes an example metric definition, where the `uuid` metric is the GitLab
instance unique identifier.

```yaml
key_path: uuid
description: GitLab instance unique identifier
product_section: analytics
product_stage: analytics
product_group: analytics_instrumentation
value_type: string
status: active
milestone: 9.1
instrumentation_class: UuidMetric
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1521
time_frame: none
data_source: database
distribution:
- ce
- ee
tier:
- free
- premium
- ultimate
```

### Create a new metric definition

The GitLab codebase provides dedicated generators to create new metrics, which also create valid metric definition files:

- [internal events generator](../internal_event_instrumentation/quick_start.md)
- [metric instrumentation class generator](metrics_instrumentation.md#create-a-new-metric-instrumentation-class)

For uniqueness, the generated files include a timestamp prefix in ISO 8601 format.

### Performance Indicator Metrics

To use a metric definition to manage [performance indicator](https://about.gitlab.com/handbook/product/analytics-instrumentation-guide/#implementing-product-performance-indicators):

1. Create a merge request that includes related changes.
1. Use labels `~"analytics instrumentation"`, `"~Data Warehouse::Impact Check"`.
1. Update the metric definition `performance_indicator_type` [field](metrics_dictionary.md#metrics-definition-and-validation).
1. Create an issue in GitLab Product Data Insights project with the [PI Chart Help template](https://gitlab.com/gitlab-data/product-analytics/-/issues/new?issuable_template=PI%20Chart%20Help) to have the new metric visualized.

## Metrics Dictionary

[Metrics Dictionary is a separate application](https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/metric-dictionary).

All metrics available in Service Ping are in the [Metrics Dictionary](https://metrics.gitlab.com/).

### Copy query to clipboard

To check if a metric has data in Sisense, use the copy query to clipboard feature. This copies a query that's ready to use in Sisense. The query gets the last five service ping data for GitLab.com for a given metric. For information about how to check if a Service Ping metric has data in Sisense, see this [demo](https://www.youtube.com/watch?v=n4o65ivta48).
