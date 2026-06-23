import { forwardRef, useCallback, useEffect, useState, type ChangeEvent } from "react";
import {
  InlineCellEditor,
  type InlineCellEditorHandle,
  useInlineCellForm,
} from "@/components/inline-cell-editing";
import { purchaseItemResource } from "@/components/purchase-item-cells/resource";
import routes from "@/utils/routes";
import type { PurchaseItemRecord } from "../types";

type ShippingCostEditorProps = {
  item: PurchaseItemRecord;
  onAutoOpen?: () => void;
  autoFocus?: boolean;
  onBulkSave?: () => void;
};

export const InlineShippingCostEditor = forwardRef<InlineCellEditorHandle, ShippingCostEditorProps>(
  function InlineShippingCostEditor({ item, onAutoOpen, autoFocus = true, onBulkSave }, ref) {
    const [hideDefaultZero, setHideDefaultZero] = useState(true);
    const form = useInlineCellForm({
      editedRecord: item,
      attributeName: "shipping_cost",
      route: routes.purchaseItemsShippingCosts.update,
      ...purchaseItemResource,
      normalizeValueForSave: normalizeShippingCostValue,
      onOpen: onAutoOpen,
    });

    useEffect(() => {
      if (!form.isOpen) setHideDefaultZero(true);
    }, [form.isOpen]);

    const { onChange } = form;
    const handleChange = useCallback(
      (event: ChangeEvent<HTMLInputElement>) => {
        setHideDefaultZero(false);
        onChange(event);
      },
      [onChange],
    );

    const inputValue = hideDefaultZero && form.value === "0" ? "" : form.value;
    const fieldId = `purchase_item_${item.id}_shipping_cost`;

    return (
      <InlineCellEditor
        ref={ref}
        ariaLabel="Edit shipping cost"
        displayClassName="font-mono text-sm"
        displayValue={Number(item.shipping_cost) > 0 ? item.shipping_cost : ""}
        error={form.error}
        fieldId={fieldId}
        fieldLabel="Shipping cost"
        form={form}
        onSave={onBulkSave ?? form.save}
        tdClassName="text-center min-w-24"
      >
        <input
          autoFocus={autoFocus}
          className="border rounded px-2 py-1 text-sm w-full"
          id={fieldId}
          min="0"
          onChange={handleChange}
          step="1"
          type="number"
          value={inputValue}
        />
      </InlineCellEditor>
    );
  },
);

function normalizeShippingCostValue(value: string) {
  return value.trim() === "" ? "0" : value;
}
