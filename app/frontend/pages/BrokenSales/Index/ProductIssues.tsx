import { Link, useForm, usePage } from "@inertiajs/react";
import { useCallback, type ChangeEvent } from "react";

import FormError from "@/components/FormError";
import { countLabel } from "@/utils/countLabel";
import routes from "@/utils/routes";

import type { AssignmentIssue, ProductIssueRow } from "../types";
import EmptyIssues from "./EmptyIssues";
import { issuePath } from "./issuePath";
import { reloadProps } from "./reloadProps";

export default function ProductIssues({ issues }: { issues: AssignmentIssue[] }) {
  if (issues.length === 0) {
    return <EmptyIssues>No Products have orders that need a Variant</EmptyIssues>;
  }

  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Orders</th>
            <th>Active orders</th>
            <th>Revenue</th>
            <th>Closed orders</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isProductRow(issue) ? <ProductRow key={issue.id} row={issue} /> : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function ProductRow({ row }: { row: ProductIssueRow }) {
  return (
    <tr aria-label={row.product_title}>
      <td>{row.product_title}</td>
      <td>
        <Link
          href={issuePath({
            issue_type: "sale_items",
            view: "orders",
            product_id: row.id,
          })}
        >
          {countLabel(row.order_count, "order")}
        </Link>
      </td>
      <td>{row.active_order_count}</td>
      <td className="font-mono">{row.revenue}</td>
      <td>
        <ClosedOrderRepair row={row} />
      </td>
    </tr>
  );
}

function ClosedOrderRepair({ row }: { row: ProductIssueRow }) {
  const page = usePage();
  const form = useForm({ variant_id: "" });
  const { data, post, setData, transform } = form;
  const onChange = useCallback(
    (event: ChangeEvent<HTMLSelectElement>) => setData({ variant_id: event.target.value }),
    [setData],
  );
  const assign = useCallback(() => {
    const variant = row.candidates.find((candidate) => String(candidate.value) === data.variant_id);
    if (!variant || !window.confirm(confirmation(row, variant.label))) return;

    transform((values) => ({
      closed_order_repair: values,
      return_to: page.url,
    }));
    post(
      routes.brokenSalesClosedOrderRepairs.create.path({
        product_id: row.id,
      }),
      {
        only: reloadProps,
        preserveScroll: true,
      },
    );
  }, [data.variant_id, page.url, post, row, transform]);

  if (row.closed_line_count === 0) return "No closed orders";
  if (row.candidates.length === 0) return "No repair candidates";

  return (
    <div className="flex flex-wrap items-center gap-2">
      <select
        aria-label={`Variant for closed orders of ${row.product_title}`}
        onChange={onChange}
        value={form.data.variant_id}
      >
        <option disabled value="">
          Select Variant
        </option>
        {row.candidates.map((candidate) => (
          <option key={candidate.value} value={candidate.value}>
            {candidate.label}
          </option>
        ))}
      </select>
      <button
        className="btn_xs btn_green"
        disabled={form.data.variant_id === "" || form.processing}
        onClick={assign}
        type="button"
      >
        Assign to closed orders
      </button>
      <FormError>{form.errors.variant_id}</FormError>
    </div>
  );
}

function confirmation(row: ProductIssueRow, variantLabel: string) {
  return `Assign ${variantLabel} to ${countLabel(
    row.closed_line_count,
    "closed order line",
  )} of ${row.product_title}? Lines with linked purchases are skipped.`;
}

function isProductRow(issue: AssignmentIssue): issue is ProductIssueRow {
  return issue.kind === "product";
}
