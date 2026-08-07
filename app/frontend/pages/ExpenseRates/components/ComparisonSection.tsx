import Amount from "@/components/Amount";
import DetailsChevron from "@/components/DetailsChevron";
import MetricLabel from "@/components/profitability/MetricLabel";
import { financialMetricHints } from "@/components/profitability/metricLabels";
import { Fragment } from "react";
import type { ComparisonRow } from "../types";

export default function ComparisonSection({ comparison }: { comparison: ComparisonRow[] }) {
  if (comparison.length === 0) {
    return (
      <section className="table_card">
        <h3>Estimated vs. Actual OpEx</h3>
        <div className="table_empty">
          <p>
            This is a month-by-month comparison of the operating expenses your OpEx rates estimate
            against what was actually spent. It fills in once you have OpEx rates and revenue
            recorded for at least one month.
          </p>
        </div>
      </section>
    );
  }

  return (
    <section className="table_card">
      <h3>Estimated vs. Actual OpEx</h3>
      <table>
        <thead>
          <tr>
            <th>Month</th>
            <th className="text-right">
              <MetricLabel anchor="monthlyRevenue" hint={financialMetricHints.monthlyRevenue}>
                Revenue
              </MetricLabel>
            </th>
            <th className="text-right">
              <MetricLabel anchor="estimatedOpEx" hint={financialMetricHints.estimatedOpEx}>
                Estimated OpEx
              </MetricLabel>
            </th>
            <th className="text-right">
              <MetricLabel anchor="actualOpEx" hint={financialMetricHints.actualOpEx}>
                Actual OpEx
              </MetricLabel>
            </th>
            <th className="text-right">
              <MetricLabel anchor="comparison" hint={financialMetricHints.comparison}>
                Comparison
              </MetricLabel>
            </th>
          </tr>
        </thead>
        <tbody>
          {comparison.map((row) => (
            <Fragment key={row.month}>
              <tr>
                <td>{row.month}</td>
                <td className="text-right">
                  <Amount value={row.revenue} />
                </td>
                <td className="text-right">
                  <Amount value={row.assumed_total} />
                </td>
                <td className="text-right">
                  <Amount value={row.actual_total} />
                </td>
                <td className="text-right">
                  <ComparisonResult comparison={row.comparison} />
                </td>
              </tr>
              {row.by_rate.length > 0 && (
                <tr>
                  <td colSpan={5}>
                    <details className="group">
                      <summary className="w-fit flex items-center gap-2 cursor-pointer text-sm">
                        OpEx rate breakdown
                        <DetailsChevron />
                      </summary>
                      <ul className="mt-2 text-sm">
                        {row.by_rate.map((entry) => (
                          <li className="flex justify-between" key={entry.label}>
                            <span>{entry.label}</span>
                            <span>
                              <Amount value={entry.assumed} /> estimated ·{" "}
                              <Amount value={entry.actual} /> actual
                            </span>
                          </li>
                        ))}
                      </ul>
                    </details>
                  </td>
                </tr>
              )}
            </Fragment>
          ))}
        </tbody>
      </table>
    </section>
  );
}

function ComparisonResult({ comparison }: { comparison: ComparisonRow["comparison"] }) {
  if (comparison.relation === "equal") return <>On estimate</>;

  return (
    <>
      <Amount value={comparison.amount} /> {comparison.relation} estimate
    </>
  );
}
