defmodule Mix.Tasks.CallGoogle do
  use Mix.Task
  use Plausible.Repo
  require Logger

  @token "REDACTED_UPSTREAM_TOKEN"
  @view_id "204615196"
  @dimensions ["ga:date"]
  @metrics ["ga:users", "ga:pageviews", "ga:bounces", "ga:sessions", "ga:sessionDuration"]

  def run(_) do
    Mix.Task.run("app.start")

    report = %{
      viewId: @view_id,
      dateRanges: [
        %{
          # The earliest valid date
          startDate: "2005-01-01",
          endDate: "2019-12-05"
        }
      ],
      dimensions: Enum.map(@dimensions, &%{name: &1, histogramBuckets: []}),
      metrics: Enum.map(@metrics, &%{expression: &1}),
      hideTotals: true,
      hideValueRanges: true,
      orderBys: [
        %{
          fieldName: "ga:date",
          sortOrder: "DESCENDING"
        }
      ],
      pageSize: 100_00,
      pageToken: ""
    }

    Logger.debug(report)

    res =
      HTTPoison.post!(
        "https://analyticsreporting.googleapis.com/v4/reports:batchGet",
        Jason.encode!(%{reportRequests: [report]}),
        Authorization: "Bearer #{@token}"
      )

    Logger.debug(res.body)
  end
end
