import { Link } from "@inertiajs/react";

import type { AssignmentIssue, SkuCollisionIssue } from "../types";
import EmptyIssues from "./EmptyIssues";

export default function SkuCollisions({ issues }: { issues: AssignmentIssue[] }) {
  if (issues.length === 0) return <EmptyIssues>No Variants share a SKU</EmptyIssues>;

  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>SKU</th>
            <th>Product / Variant</th>
            <th>Colliding with</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isSkuCollisionIssue(issue) ? <SkuCollisionRow issue={issue} key={issue.id} /> : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function SkuCollisionRow({ issue }: { issue: SkuCollisionIssue }) {
  return (
    <tr aria-label={`SKU collision ${issue.sku} on ${issue.product_title}`}>
      <td>{issue.sku}</td>
      <td>
        <Link href={issue.edit_path}>
          {issue.product_title} / {issue.variant_label}
        </Link>
      </td>
      <td>
        {issue.colliding_with.map((other) => (
          <Link href={other.edit_path} key={other.variant_id}>
            {other.product_title} / {other.variant_label}
          </Link>
        ))}
      </td>
    </tr>
  );
}

function isSkuCollisionIssue(issue: AssignmentIssue): issue is SkuCollisionIssue {
  return issue.kind === "sku_collision";
}
