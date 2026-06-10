import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useState,
  type ChangeEvent,
} from "react";
import FormError from "@/components/FormError";
import {
  InlineCellForm,
  InlineCellTd,
  InlineCellTrigger,
  useInlineCellForm,
} from "@/components/inline-cell-editing";
import routes from "@/utils/routes";
import type { PurchaseItemRecord } from "../types";

type ShippingCostEditorProps = {
  item: PurchaseItemRecord;
  onAutoOpen?: () => void;
  autoFocus?: boolean;
  onBulkSave?: () => void;
};

export const InlineShippingCostEditor = forwardRef<
  { open(): void; close(): void; getValue(): string },
  ShippingCostEditorProps
>(function InlineShippingCostEditor({ item, onAutoOpen, autoFocus = true, onBulkSave }, ref) {
  const [hideDefaultZero, setHideDefaultZero] = useState(true);
  const { isOpen, isSaved, open, close, openSilently, error, onChange, save, value } =
    useInlineCellForm({
      editedRecord: item,
      attributeName: "shipping_cost",
      route: routes.purchaseItemsShippingCosts.update,
      normalizeValueForSave: normalizeShippingCostValue,
      onOpen: onAutoOpen,
    });

  useImperativeHandle(ref, () => ({ open: openSilently, close, getValue: () => value }));

  useEffect(() => {
    if (!isOpen) setHideDefaultZero(true);
  }, [isOpen]);

  const handleChange = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      setHideDefaultZero(false);
      onChange(event);
    },
    [onChange],
  );

  const displayValue = hideDefaultZero && value === "0" ? "" : value;

  return (
    <InlineCellTd
      className="text-center min-w-24"
      isSaved={isSaved}
      onOpen={isOpen ? undefined : open}
    >
      {isOpen ? (
        <InlineCellForm onCancel={close} onSave={onBulkSave ?? save}>
          <label className="sr-only" htmlFor={`purchase_item_${item.id}_shipping_cost`}>
            Shipping cost
          </label>
          <input
            autoFocus={autoFocus}
            className="border rounded px-2 py-1 text-sm w-full"
            id={`purchase_item_${item.id}_shipping_cost`}
            min="0"
            onChange={handleChange}
            step="1"
            type="number"
            value={displayValue}
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
});

function normalizeShippingCostValue(value: string) {
  return value.trim() === "" ? "0" : value;
}
