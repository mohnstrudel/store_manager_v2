import { InlineCellEditor, useInlineCellForm } from "@/components/inline-cell-editing";
import routes from "@/utils/routes";

import type { PurchaseAssignmentIssue, SaleItemAssignmentIssue } from "../types";

export const reloadProps = ["issues", "counts", "pagination", "repairable"];

export default function VariantRepairCell({
  issue,
}: {
  issue: PurchaseAssignmentIssue | SaleItemAssignmentIssue;
}) {
  const isPurchase = issue.kind === "purchase";
  const form = useInlineCellForm({
    editedRecord: issue,
    attributeName: "variant_id",
    route: isPurchase ? routes.brokenSalesPurchases.update : routes.brokenSalesSaleItems.update,
    collection: "issues",
    paramKey: isPurchase ? "purchase" : "sale_item",
    idParam: "id",
    reloadProps,
    mapNewValueToState: (newValue) => {
      const selected = issue.candidates.find((candidate) => candidate.value === Number(newValue));
      return {
        variant_id: Number(newValue),
        current_variant_label: selected?.label ?? issue.current_variant_label,
      };
    },
  });
  const fieldId = `${issue.kind}-${issue.id}-variant`;

  if (issue.candidates.length === 0) {
    return <td>No repair candidates</td>;
  }

  return (
    <InlineCellEditor
      ariaLabel={`Edit Variant for ${issue.reference}`}
      displayValue={issue.current_variant_label}
      error={form.error}
      fieldId={fieldId}
      fieldLabel={`Variant for ${issue.reference}`}
      form={form}
      onSave={form.save}
    >
      <select
        aria-label={`Variant for ${issue.reference}`}
        id={fieldId}
        onChange={form.onChange}
        value={form.value}
      >
        <option disabled value="">
          Select Variant
        </option>
        {issue.candidates.map((candidate) => (
          <option key={candidate.value} value={candidate.value}>
            {candidate.label}
          </option>
        ))}
      </select>
    </InlineCellEditor>
  );
}
