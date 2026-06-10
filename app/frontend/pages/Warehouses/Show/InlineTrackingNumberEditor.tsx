import { useCallback, useState } from "react";
import FormError from "@/components/FormError";
import {
  InlineCellForm,
  InlineCellTd,
  InlineCellTrigger,
  useInlineCellForm,
} from "@/components/inline-cell-editing";
import routes from "@/utils/routes";
import type { WarehousePurchaseItemRecord } from "../types";

type TrackingNumberEditorProps = {
  item: WarehousePurchaseItemRecord;
  onAutoOpenShipping?: () => void;
};

export function InlineTrackingNumberEditor({
  item,
  onAutoOpenShipping,
}: TrackingNumberEditorProps) {
  const [shippingError, setShippingError] = useState("");
  const requiresShippingCompany = !item.shipping_company_id;

  const {
    isOpen,
    isSaved,
    open,
    close,
    error: serverError,
    onChange,
    save,
    value,
  } = useInlineCellForm({
    editedRecord: item,
    attributeName: "tracking_number",
    route: routes.purchaseItemsTrackingNumbers.update,
    errorFrom: trackingNumberError,
    onOpen: !item.shipping_company_id ? onAutoOpenShipping : undefined,
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
    close();
  }, [close]);

  return (
    <InlineCellTd
      className="text-center max-w-56"
      isSaved={isSaved}
      onOpen={isOpen ? undefined : open}
    >
      {isOpen ? (
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
      ) : (
        <InlineCellTrigger ariaLabel="Edit tracking number" onOpen={open}>
          {item.tracking_number ? (
            <span className="break-all text-sm font-mono">{item.tracking_number}</span>
          ) : null}
        </InlineCellTrigger>
      )}
    </InlineCellTd>
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
