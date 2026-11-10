import { Link } from "@inertiajs/react";

import { countLabel } from "@/utils/countLabel";

import type { AssignmentIssue, PurchaseAssignmentIssue } from "../types";
import EmptyIssues from "./EmptyIssues";
import VariantRepairCell from "./VariantRepairCell";

export default function Purchases({ issues }: { issues: AssignmentIssue[] }) {
  if (issues.length === 0) return <EmptyIssues>No Purchases need a Variant</EmptyIssues>;

  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>Record</th>
            <th>Evidence</th>
            <th>Impact</th>
            <th>Variant repair</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isPurchaseIssue(issue) ? <PurchaseRow issue={issue} key={issue.id} /> : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function PurchaseRow({ issue }: { issue: PurchaseAssignmentIssue }) {
  return (
    <tr aria-label={issue.reference}>
      <td>
        <Link href={issue.record_path}>{issue.reference}</Link>
      </td>
      <td>
        <div>{issue.product_title}</div>
        <div>{issue.current_variant_label}</div>
        <small>{reasonLabel(issue.reason)}</small>
      </td>
      <td>{purchaseImpact(issue)}</td>
      <VariantRepairCell issue={issue} />
    </tr>
  );
}

function reasonLabel(reason: string) {
  return (
    {
      missing_product: "Missing Product",
      missing_variant: "Missing Variant",
      product_mismatch: "Product / Variant mismatch",
      purchase_identity: "Purchase identity mismatch",
      sale_item_identity: "SaleItem identity mismatch",
    }[reason] ?? reason
  );
}

function purchaseImpact(issue: PurchaseAssignmentIssue) {
  return `${countLabel(issue.inventory_units, "inventory unit")}; ${countLabel(
    issue.linked_units,
    "linked unit",
  )}`;
}

function isPurchaseIssue(issue: AssignmentIssue): issue is PurchaseAssignmentIssue {
  return issue.kind === "purchase";
}
