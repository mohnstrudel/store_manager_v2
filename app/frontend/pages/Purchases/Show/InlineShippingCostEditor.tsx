import { forwardRef, useImperativeHandle } from "react";
import FormError from "@/components/FormError";
import { InlineCellForm, InlineCellTd, InlineCellTrigger } from "@/components/InlineCellEditor";
import { useInlineCellForm } from "@/lib/useInlineCellForm";
import routes from "@/lib/routes";
import type { PurchaseItemRecord } from "../types";

type ShippingCostEditorProps = {
  item: PurchaseItemRecord;
  onAutoOpen?: () => void;
};

export const InlineShippingCostEditor = forwardRef<{ open(): void }, ShippingCostEditorProps>(
  function InlineShippingCostEditor({ item, onAutoOpen }, ref) {
    const { isOpen, isSaved, open, close, openSilently, error, onChange, save, value } =
      useInlineCellForm({
        editedRecord: item,
        attributeName: "shipping_cost",
        route: routes.purchaseItemsShippingCosts.update,
        onOpen: onAutoOpen,
      });

    useImperativeHandle(ref, () => ({ open: openSilently }));

    return (
      <InlineCellTd
        className="text-center min-w-24"
        isSaved={isSaved}
        onOpen={isOpen ? undefined : open}
      >
        {isOpen ? (
          <InlineCellForm onCancel={close} onSave={save}>
            <label className="sr-only" htmlFor={`purchase_item_${item.id}_shipping_cost`}>
              Shipping cost
            </label>
            <input
              autoFocus
              className="border rounded px-2 py-1 text-sm w-full"
              id={`purchase_item_${item.id}_shipping_cost`}
              min="0"
              onChange={onChange}
              step="1"
              type="number"
              value={value}
            />
            <FormError>{error}</FormError>
          </InlineCellForm>
        ) : (
          <InlineCellTrigger ariaLabel="Edit shipping cost" onOpen={open}>
            {Number(item.shipping_cost) > 0 ? (
              <span className="font-mono text-sm">{item.shipping_cost}</span>
            ) : null}
          </InlineCellTrigger>
        )}
      </InlineCellTd>
    );
  },
);
