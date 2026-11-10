import { Link, useForm, usePage } from "@inertiajs/react";
import { useCallback } from "react";

import { countLabel } from "@/utils/countLabel";
import routes from "@/utils/routes";

import type { AssignmentIssue, PurchaseItemLinkIssue } from "../types";
import EmptyIssues from "./EmptyIssues";
import { reloadProps } from "./reloadProps";

export default function PurchaseLinks({ issues }: { issues: AssignmentIssue[] }) {
  if (issues.length === 0) return <EmptyIssues>No PurchaseItem links need repair</EmptyIssues>;

  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>PurchaseItem</th>
            <th>Purchase identity</th>
            <th>SaleItem identity</th>
            <th>Impact</th>
            <th>Repair</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isPurchaseItemLinkIssue(issue) ? (
              <PurchaseLinkRow issue={issue} key={issue.id} />
            ) : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function PurchaseLinkRow({ issue }: { issue: PurchaseItemLinkIssue }) {
  return (
    <tr aria-label={`PurchaseItem link ${issue.id}`}>
      <td>#{issue.id}</td>
      <td>
        <Link href={issue.purchase_path}>
          {issue.purchase_product_title} / {issue.purchase_variant_label}
        </Link>
      </td>
      <td>
        <Link href={issue.sale_path}>
          {issue.sale_product_title} / {issue.sale_variant_label}
        </Link>
      </td>
      <td>{linkImpact(issue)}</td>
      <td>
        <LinkRepairButton issue={issue} />
      </td>
    </tr>
  );
}

function linkImpact(issue: PurchaseItemLinkIssue) {
  return `${countLabel(
    issue.exact_replacements_available,
    "exact replacement",
  )} available; ${countLabel(issue.remaining_capacity_after_unlink, "open slot")} after unlink`;
}

function LinkRepairButton({ issue }: { issue: PurchaseItemLinkIssue }) {
  const page = usePage();
  const { patch, processing, transform } = useForm({});
  const repair = useCallback(() => {
    transform(() => ({ return_to: page.url }));
    patch(routes.brokenSalesPurchaseItemLinks.update.path({ id: issue.id }), {
      only: reloadProps,
      preserveScroll: true,
    });
  }, [issue.id, page.url, patch, transform]);

  return (
    <button
      aria-label={`Repair PurchaseItem link ${issue.id}`}
      className="btn_xs btn_green"
      disabled={processing}
      onClick={repair}
      type="button"
    >
      Repair link
    </button>
  );
}

function isPurchaseItemLinkIssue(issue: AssignmentIssue): issue is PurchaseItemLinkIssue {
  return issue.kind === "purchase_item_link";
}
