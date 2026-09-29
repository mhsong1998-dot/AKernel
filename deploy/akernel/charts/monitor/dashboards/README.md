# ADX dashboards in the monitor chart

The chart bundles the four Grafana dashboards maintained by [agent-dx](https://gitcode.com/openJiuwen/agent-dx/blob/56b3b4891944c9efd557b737c80fa62c80d84231/build/observability/grafana/README.md).
Source revision: `56b3b4891944c9efd557b737c80fa62c80d84231` (merged observability PR).
The ADX JSON files are copied without editing their queries; refresh them together when the upstream metric contract changes.

| File | Dashboard UID |
| --- | --- |
| [adx-observability.json](adx-observability.json) | `adx-observability` |
| [adx-schedule.json](adx-schedule.json) | `adx-schedule` |
| [adx-data-plane.json](adx-data-plane.json) | `adx-data-plane` |
| [adx-process-resources.json](adx-process-resources.json) | `adx-process-resources` |

Core collectors populate `adx_env` from `core.monitoring.akernelEnv` for both metrics and logs. Existing `akernel_env` labels remain available to the other dashboards. Loki must index `adx_env`; the bundled configuration enables this. Old records without the new label remain accessible through the existing views.

Grafana provisioning reads all JSON files in this directory. With `grafanaServer.env.serveFromSubPath=true`, the rendered dashboard navigation adds `/grafana` to `/d/` links. The source JSON remains identical to the agent-dx files. If importing by hand, use the ADX README's data source and label requirements and adjust links for the actual Grafana base path.
