import { forwardRef, useImperativeHandle } from "react";
import FormError from "@/components/FormError";
import { InlineCellForm, InlineCellTd, InlineCellTrigger } from "@/components/InlineCellEditor";
import { useInlineCellForm } from "@/lib/useInlineCellForm";
import routes from "@/lib/routes";
import type { PurchaseItemRecord, ShippingCompanyOption } from "../types";

type ShippingCompanyEditorProps = {
  item: PurchaseItemRecord;
  onAutoOpen?: () => void;
  shippingCompanies: ShippingCompanyOption[];
  autoFocus?: boolean;
  onBulkSave?: () => void;
};

export const InlineShippingCompanyEditor = forwardRef<
  { open(): void; save(): void },
  ShippingCompanyEditorProps
>(function InlineShippingCompanyEditor(
  { item, onAutoOpen, shippingCompanies, autoFocus = true, onBulkSave },
  ref,
) {
    const { isOpen, isSaved, open, close, openSilently, error, onChange, save, value } =
      useInlineCellForm({
        editedRecord: item,
        attributeName: "shipping_company_id",
        route: routes.purchaseItemsShippingCompanies.update,
        mapNewValueToState: (shippingCompanyId) => ({
          shipping_company_id: shippingCompanyId ? Number(shippingCompanyId) : null,
          shipping_company_name: shippingCompanyName(shippingCompanies, shippingCompanyId),
        }),
        onOpen: onAutoOpen,
      });

    useImperativeHandle(ref, () => ({ open: openSilently, save }));

    return (
      <InlineCellTd
        className="text-center min-w-32"
        isSaved={isSaved}
        onOpen={isOpen ? undefined : open}
      >
        {isOpen ? (
          <InlineCellForm onCancel={close} onSave={onBulkSave ?? save}>
            <label className="sr-only" htmlFor={`purchase_item_${item.id}_shipping_company_id`}>
              Shipping company
            </label>
            <select
              autoFocus={autoFocus}
              className="border rounded px-2 py-1 text-sm w-full min-w-35"
              id={`purchase_item_${item.id}_shipping_company_id`}
              onChange={onChange}
              value={value}
            >
              <option value="">Select a shipping company</option>
              {shippingCompanies.map((sc) => (
                <option key={sc.id} value={sc.id}>
                  {sc.name}
                </option>
              ))}
            </select>
            <FormError>{error}</FormError>
          </InlineCellForm>
        ) : (
          <InlineCellTrigger ariaLabel="Edit shipping company" onOpen={open}>
            {item.shipping_company_name ? <div>{item.shipping_company_name}</div> : null}
          </InlineCellTrigger>
        )}
      </InlineCellTd>
    );
});

function shippingCompanyName(shippingCompanies: ShippingCompanyOption[], id: string) {
  return shippingCompanies.find((sc) => String(sc.id) === id)?.name || "";
}
