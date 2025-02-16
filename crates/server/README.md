# server

remotehiro's web service

## Database dependencies

### remotehiro.db

This contains the data like jobs, supported currencies, regions, etc. Currently,
`server` only needs an RO connection from `remotehiro.db` as third-party users
(which is anyone besides the person writing the migration files a.k.a me) are
unable to create posts.

### warehouse.db (WIP)

`warehouse.db` contains all the aggregations that make data fetching easier, and
inexpensive to do. Operations that don't require frequent updates/writes but are
expensive to compute when needed may be optimized for reads instead.

#### Aggregations

1. `warehouse.jobs_salaries_in_alt_currencies`. Contains the currencies in all
alternate currencies. e.g if a job is declared to be in EUR, then we need to be
able to compute the USD, JPY, etc. so that when a user chooses to search in their
preferred currency, it is trivial to support.
2. `warehouse.jobs_rendered_html`. Jobs descriptions are stored in a markdown
format. This description in rendered to HTML on the fly which makes it more
expensive to do for what is essentially the same description; wasting resources.


#### Update dependencies

There are three cases that would require an update/insert to `warehouse.db`:

1. When a new job is created
2. When an existing job's salary details are updated. (e.g new location, new salary, new currency, new description)
3. When an external dependency of the aggregation is updated. (e.g ECB rates)

The proposed mechanism to support this is through an internal-only endpoint
`POST /api/warehouse/generate`.

##### `warehouse.jobs_salaries_in_alt_currencies`

Payload:

```json
{
    "aggregation_name": "jobs_salaries_in_alt_currencies",
    "job_ids": [ARRAY OF JOBS IDs | null]
}
```

If `job_ids` is `undefined`, or `null`, then _all_ jobs will be regenerated. But
if it's provided, then only the specified jobs that match the provided IDs will
be (re)generated. In both cases, this must be upserted. If a job doesn't have an
aggregation row yet, it needs to be created, and if it exists, it must be updated.

To address update dependency #1, and #2, the endpoint needs to be manually called
to trigger an update.

To address update dependency #3, this needs to be automated through a CRON via
a `systemd` service. At every EOD, the endpoint needs to be called for all jobs
as the rates will likely be different.

##### `warehouse.jobs_rendered_descriptions`

Payload:

```json
{
    "aggregation_name": "jobs_rendered_descriptions",
    "job_ids": [ARRAY OF JOBS IDs | null]
}
```

This aggregation currently only has #1, and #2 as its update dependencies which
means it has to be manually triggered after such events occur.
