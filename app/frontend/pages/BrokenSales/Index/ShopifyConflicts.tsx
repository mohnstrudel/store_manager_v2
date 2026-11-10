import { Link } from "@inertiajs/react";

import type { AssignmentIssue, ShopifyConflictIssue } from "../types";
import EmptyIssues from "./EmptyIssues";

export default function ShopifyConflicts({ issues }: { issues: AssignmentIssue[] }) {
  if (issues.length === 0)
    return <EmptyIssues>No Shopify Variants have conflicting options</EmptyIssues>;

  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Shopify Variant</th>
            <th>Shopify options</th>
            <th>Already used by</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isShopifyConflictIssue(issue) ? (
              <ShopifyConflictRow issue={issue} key={issue.id} />
            ) : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function ShopifyConflictRow({ issue }: { issue: ShopifyConflictIssue }) {
  return (
    <tr aria-label={`Shopify conflict ${issue.store_id} on ${issue.product_title}`}>
      <td>
        <Link href={issue.edit_path}>{issue.product_title}</Link>
      </td>
      <td>
        {issue.sku || "No SKU"}
        <br />
        <span className="text-xs text-gray-400 dark:text-gray-500">{issue.store_id}</span>
      </td>
      <td>
        {issue.shopify_options.map((option) => `${option.name}: ${option.value}`).join(" / ")}
      </td>
      <td>
        {issue.conflicting_variant_label
          ? `${issue.conflicting_variant_label} (${issue.conflicting_variant_sku || "No SKU"})`
          : "Deleted Variant"}
      </td>
    </tr>
  );
}

function isShopifyConflictIssue(issue: AssignmentIssue): issue is ShopifyConflictIssue {
  return issue.kind === "shopify_conflict";
}
