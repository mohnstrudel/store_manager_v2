import { useCallback, useState } from "react";
import FormError from "@/components/FormError";
import { InlineCellForm, InlineCellTrigger } from "@/components/InlineCellEditor";
import { useInlineCellForm } from "@/lib/useInlineCellForm";
import type { WarehousePurchaseItemRecord } from "../types";

type TrackingNumberEditorProps = {
  item: WarehousePurchaseItemRecord;
  isOpen: boolean;
  onClose: () => void;
  onOpen: () => void;
  onSaved: (itemId: number) => void;
  returnTo: string;
};

export function InlineTrackingNumberEditor({
  item,
  isOpen,
  onClose,
  onOpen,
  onSaved,
  returnTo,
}: TrackingNumberEditorProps) {
  const [shippingError, setShippingError] = useState("");
  const requiresShippingCompany = !item.shipping_company_id;

  const {
    error: serverError,
    onChange,
    save,
    value,
  } = useInlineCellForm({
    isOpen,
    record: item,
    field: "tracking_number",
    returnTo,
    updatePath: item.tracking_update_path,
    param: "purchase_item",
    collection: "purchase_items",
    toRecordPatch: (trackingNumber) => ({ tracking_number: trackingNumber }),
    errorFrom: trackingNumberError,
    onClose,
    onOpen,
    onSaved: () => onSaved(item.id),
  });

  const error = requiresShippingCompany ? shippingError : serverError;

  const saveTrackingNumber = useCallback(() => {
    if (requiresShippingCompany) {
      setShippingError("Shipping company is required");
      return;
    }
    save();
  }, [requiresShippingCompany, save]);

  const cancelEditing = useCallback(() => {
    setShippingError("");
    onClose();
  }, [onClose]);

  if (!isOpen) {
    return (
      <InlineCellTrigger ariaLabel="Edit tracking number" onOpen={onOpen}>
        {item.tracking_number ? (
          <span className="break-words text-sm font-mono">{item.tracking_number}</span>
        ) : null}
      </InlineCellTrigger>
    );
  }

  return (
    <InlineCellForm onCancel={cancelEditing} onSave={saveTrackingNumber}>
      <label className="sr-only" htmlFor={`purchase_item_${item.id}_tracking_number`}>
        Tracking number
      </label>
      <input
        autoComplete="off"
        autoFocus
        className="border rounded px-2 py-1 text-sm w-full"
        id={`purchase_item_${item.id}_tracking_number`}
        onChange={onChange}
        placeholder="Enter tracking number"
        type="text"
        value={value}
      />
      <FormError>{error}</FormError>
    </InlineCellForm>
  );
}

function trackingNumberError(errors: Record<string, string>) {
  if (Object.keys(errors).length === 0) return "";

  return (
    errors.tracking_number ||
    errors.shipping_company_id ||
    errors.base ||
    "Could not save tracking number"
  );
}
