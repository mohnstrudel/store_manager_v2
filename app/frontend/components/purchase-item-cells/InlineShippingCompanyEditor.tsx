import { forwardRef } from "react";
import {
  InlineCellEditor,
  type InlineCellEditorHandle,
  useInlineCellForm,
} from "@/components/inline-cell-editing";
import routes from "@/utils/routes";
import {
  purchaseItemResource,
  type PurchaseItemCellRecord,
  type ShippingCompanyOption,
} from "./resource";

type ShippingCompanyEditorProps = {
  item: PurchaseItemCellRecord;
  shippingCompanies: ShippingCompanyOption[];
  onAutoOpen?: () => void;
  autoFocus?: boolean;
  bulkError?: string;
  onBulkSave?: () => void;
};

export const InlineShippingCompanyEditor = forwardRef<
  InlineCellEditorHandle,
  ShippingCompanyEditorProps
>(function InlineShippingCompanyEditor(
  { item, shippingCompanies, onAutoOpen, autoFocus = true, bulkError, onBulkSave },
  ref,
) {
  const form = useInlineCellForm({
    editedRecord: item,
    attributeName: "shipping_company_id",
    route: routes.purchaseItemsShippingCompanies.update,
    ...purchaseItemResource,
    mapNewValueToState: (shippingCompanyId) => ({
      shipping_company_id: shippingCompanyId ? Number(shippingCompanyId) : null,
      shipping_company_name: shippingCompanyName(shippingCompanies, shippingCompanyId),
    }),
    onOpen: onAutoOpen,
  });

  const fieldId = `purchase_item_${item.id}_shipping_company_id`;

  return (
    <InlineCellEditor
      ref={ref}
      ariaLabel="Edit shipping company"
      displayValue={item.shipping_company_name}
      error={bulkError || form.error}
      fieldId={fieldId}
      fieldLabel="Shipping company"
      form={form}
      onSave={onBulkSave ?? form.save}
      tdClassName="text-center min-w-32"
    >
      <select
        autoFocus={autoFocus}
        className="border rounded px-2 py-1 text-sm w-full min-w-35"
        id={fieldId}
        onChange={form.onChange}
        value={form.value}
      >
        <option value="">Select a shipping company</option>
        {shippingCompanies.map((company) => (
          <option key={company.id} value={company.id}>
            {company.name}
          </option>
        ))}
      </select>
    </InlineCellEditor>
  );
});

function shippingCompanyName(shippingCompanies: ShippingCompanyOption[], id: string) {
  return shippingCompanies.find((company) => String(company.id) === id)?.name || "";
}
