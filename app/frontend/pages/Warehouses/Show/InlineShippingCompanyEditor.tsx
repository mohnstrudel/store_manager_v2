import FormError from "@/components/FormError";
import { InlineCellForm, InlineCellTrigger } from "@/components/InlineCellEditor";
import { useInlineCellForm } from "@/lib/useInlineCellForm";
import type { ShippingCompanyOption, WarehousePurchaseItemRecord } from "../types";

type ShippingCompanyEditorProps = {
  item: WarehousePurchaseItemRecord;
  isOpen: boolean;
  onClose: () => void;
  onOpen: () => void;
  onSaved: (itemId: number) => void;
  returnTo: string;
  shippingCompanies: ShippingCompanyOption[];
};

export function InlineShippingCompanyEditor({
  item,
  isOpen,
  onClose,
  onOpen,
  onSaved,
  returnTo,
  shippingCompanies,
}: ShippingCompanyEditorProps) {
  const { error, onChange, save, value } = useInlineCellForm({
    isOpen,
    record: item,
    field: "shipping_company_id",
    returnTo,
    updatePath: item.shipping_company_update_path,
    param: "purchase_item",
    collection: "purchase_items",
    toRecordPatch: (shippingCompanyId) => ({
      shipping_company_id: shippingCompanyId ? Number(shippingCompanyId) : null,
      shipping_company_name: shippingCompanyName(shippingCompanies, shippingCompanyId),
    }),
    onClose,
    onOpen,
    onSaved: () => onSaved(item.id),
  });

  if (!isOpen) {
    return (
      <InlineCellTrigger ariaLabel="Edit shipping company" onOpen={onOpen}>
        {item.shipping_company_name ? <div>{item.shipping_company_name}</div> : null}
      </InlineCellTrigger>
    );
  }

  return (
    <InlineCellForm onCancel={onClose} onSave={save}>
      <label className="sr-only" htmlFor={`purchase_item_${item.id}_shipping_company_id`}>
        Shipping company
      </label>
      <select
        autoFocus
        className="border rounded px-2 py-1 text-sm w-full min-w-35"
        id={`purchase_item_${item.id}_shipping_company_id`}
        onChange={onChange}
        value={value}
      >
        <option value="">Select a shipping company</option>
        {shippingCompanies.map((shippingCompany) => (
          <option key={shippingCompany.id} value={shippingCompany.id}>
            {shippingCompany.name}
          </option>
        ))}
      </select>
      <FormError>{error}</FormError>
    </InlineCellForm>
  );
}

function shippingCompanyName(shippingCompanies: ShippingCompanyOption[], id: string) {
  return shippingCompanies.find((company) => String(company.id) === id)?.name || "";
}
