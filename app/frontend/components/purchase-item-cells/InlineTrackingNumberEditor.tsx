import { forwardRef, useCallback, useState } from "react";
import {
  InlineCellEditor,
  type InlineCellEditorHandle,
  useInlineCellForm,
} from "@/components/inline-cell-editing";
import routes from "@/utils/routes";
import { purchaseItemResource, type PurchaseItemCellRecord } from "./resource";

type TrackingNumberEditorProps = {
  item: PurchaseItemCellRecord;
  onAutoOpen?: () => void;
  autoFocus?: boolean;
  bulkError?: string;
  onBulkSave?: () => void;
};

export const InlineTrackingNumberEditor = forwardRef<
  InlineCellEditorHandle,
  TrackingNumberEditorProps
>(function InlineTrackingNumberEditor(
  { item, onAutoOpen, autoFocus = true, bulkError, onBulkSave },
  ref,
) {
  const [shippingError, setShippingError] = useState("");
  const requiresShippingCompany = !item.shipping_company_id;

  const form = useInlineCellForm({
    editedRecord: item,
    attributeName: "tracking_number",
    route: routes.purchaseItemsTrackingNumbers.update,
    ...purchaseItemResource,
    errorFrom: trackingNumberError,
    onOpen: onAutoOpen,
  });
  const { save, close } = form;

  const error = bulkError || (requiresShippingCompany ? shippingError : form.error);

  const saveTrackingNumber = useCallback(() => {
    if (requiresShippingCompany) {
      setShippingError("Shipping company is required");
      return;
    }
    save();
  }, [requiresShippingCompany, save]);

  const cancelEditing = useCallback(() => {
    setShippingError("");
    close();
  }, [close]);

  const fieldId = `purchase_item_${item.id}_tracking_number`;

  return (
    <InlineCellEditor
      ref={ref}
      ariaLabel="Edit tracking number"
      displayClassName="break-all text-sm font-mono"
      displayValue={item.tracking_number}
      error={error}
      fieldId={fieldId}
      fieldLabel="Tracking number"
      form={form}
      onCancel={cancelEditing}
      onSave={onBulkSave ?? saveTrackingNumber}
      tdClassName="text-center max-w-56"
    >
      <input
        autoComplete="off"
        autoFocus={autoFocus}
        className="border rounded px-2 py-1 text-sm w-full"
        id={fieldId}
        onChange={form.onChange}
        placeholder="Enter tracking number"
        type="text"
        value={form.value}
      />
    </InlineCellEditor>
  );
});

function trackingNumberError(errors: Record<string, string>) {
  if (Object.keys(errors).length === 0) return "";

  return (
    errors.tracking_number ||
    errors.shipping_company_id ||
    errors.base ||
    "Could not save tracking number"
  );
}
