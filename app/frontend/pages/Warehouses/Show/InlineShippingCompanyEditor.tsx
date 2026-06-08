import { forwardRef, useImperativeHandle } from "react";
import FormError from "@/components/FormError";
import { InlineCellForm, InlineCellTd, InlineCellTrigger, useInlineCellForm } from "@/components/inline-cell-editing";
import routes from "@/utils/routes";
import type { ShippingCompanyOption, WarehousePurchaseItemRecord } from "../types";

type ShippingCompanyEditorProps = {
  item: WarehousePurchaseItemRecord;
  shippingCompanies: ShippingCompanyOption[];
};

export const InlineShippingCompanyEditor = forwardRef<{ open(): void }, ShippingCompanyEditorProps>(
  function InlineShippingCompanyEditor({ item, shippingCompanies }, ref) {
    const { isOpen, isSaved, open, close, openSilently, error, onChange, save, value } =
      useInlineCellForm({
        editedRecord: item,
        attributeName: "shipping_company_id",
        route: routes.purchaseItemsShippingCompanies.update,
        mapNewValueToState: (shippingCompanyId) => ({
          shipping_company_id: shippingCompanyId ? Number(shippingCompanyId) : null,
          shipping_company_name: shippingCompanyName(shippingCompanies, shippingCompanyId),
        }),
      });

    useImperativeHandle(ref, () => ({ open: openSilently }));

    return (
      <InlineCellTd
        className="text-center min-w-32"
        isSaved={isSaved}
        onOpen={isOpen ? undefined : open}
      >
        {isOpen ? (
          <InlineCellForm onCancel={close} onSave={save}>
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
        ) : (
          <InlineCellTrigger ariaLabel="Edit shipping company" onOpen={open}>
            {item.shipping_company_name ? <div>{item.shipping_company_name}</div> : null}
          </InlineCellTrigger>
        )}
      </InlineCellTd>
    );
  },
);

function shippingCompanyName(shippingCompanies: ShippingCompanyOption[], id: string) {
  return shippingCompanies.find((company) => String(company.id) === id)?.name || "";
}
