import { useForm } from "@inertiajs/react";
import {
  useCallback,
  type ChangeEvent,
  useEffect,
  useEffectEvent,
  type FormEvent,
  useState,
} from "react";
import FormError from "@/components/FormError";
import type { WarehousePurchaseItemRecord } from "../types";
import {
  InlineEditorActions,
  stopInlineEditorNavigation,
  updatePurchaseItem,
} from "./InlineEditorActions";

type TrackingNumberEditorProps = {
  item: WarehousePurchaseItemRecord;
  isOpen: boolean;
  onClose: () => void;
  onOpen: () => void;
  onSaved: (itemId: number) => void;
  returnTo: string;
};

type WithPurchaseItems = { purchase_items: WarehousePurchaseItemRecord[] };

export function InlineTrackingNumberEditor({
  item,
  isOpen,
  onClose,
  onOpen,
  onSaved,
  returnTo,
}: TrackingNumberEditorProps) {
  const editor = useTrackingNumberEditor({ item, isOpen, onClose, onOpen, onSaved, returnTo });

  if (isOpen) {
    return (
      <form
        className="flex flex-col w-full gap-2 no_events"
        onAuxClick={stopInlineEditorNavigation}
        onClick={stopInlineEditorNavigation}
        onKeyDown={stopInlineEditorNavigation}
        onSubmit={editor.submitTrackingNumber}
      >
        <label className="sr-only" htmlFor={`purchase_item_${item.id}_tracking_number`}>
          Tracking number
        </label>
        <input
          autoComplete="off"
          autoFocus
          className="border rounded px-2 py-1 text-sm w-full"
          id={`purchase_item_${item.id}_tracking_number`}
          onChange={editor.changeTrackingNumber}
          placeholder="Enter tracking number"
          type="text"
          value={editor.trackingNumber}
        />
        <FormError>{editor.error}</FormError>
        <InlineEditorActions onCancel={editor.cancelEditing} />
      </form>
    );
  }

  return (
    <InlineTrackingNumberDisplay
      trackingNumber={item.tracking_number}
      onEdit={onOpen}
    />
  );
}

function InlineTrackingNumberDisplay({
  trackingNumber,
  onEdit,
}: {
  trackingNumber: string;
  onEdit: () => void;
}) {
  return (
    <div
      className="flex flex-col items-center gap-2 text-center"
      onAuxClick={stopInlineEditorNavigation}
      onClick={stopInlineEditorNavigation}
      onKeyDown={stopInlineEditorNavigation}
    >
      {trackingNumber ? (
        <span className="min-w-0 max-w-full break-words text-sm font-mono cursor-text">
          {trackingNumber}
        </span>
      ) : null}
      <button className="btn_xs btn_rounded" onClick={onEdit} type="button">
        {trackingNumber ? "Edit" : "Add"}
      </button>
    </div>
  );
}

function useTrackingNumberEditor({
  item,
  isOpen,
  onClose,
  onOpen,
  onSaved,
  returnTo,
}: TrackingNumberEditorProps) {
  const [shippingRequiredError, setShippingRequiredError] = useState("");
  const form = useForm({
    purchase_item: { tracking_number: item.tracking_number || "" },
    return_to: returnTo,
  });

  const trackingNumber = form.data.purchase_item.tracking_number;
  const error = shippingRequiredError || trackingNumberError(form.errors);
  const syncTrackingForm = useEffectEvent((nextTrackingNumber: string, nextReturnTo: string) => {
    form.setData({
      purchase_item: { tracking_number: nextTrackingNumber },
      return_to: nextReturnTo,
    });
  });

  useEffect(() => {
    if (isOpen) return undefined;

    syncTrackingForm(item.tracking_number || "", returnTo);
    return undefined;
  }, [isOpen, item.tracking_number, returnTo]);

  useEffect(() => {
    if (item.shipping_company_id) setShippingRequiredError("");
  }, [item.shipping_company_id]);

  const submitTrackingNumber = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();

      if (!item.shipping_company_id) {
        setShippingRequiredError("Shipping company is required");
        return;
      }

      setShippingRequiredError("");
      form
        .optimistic<WithPurchaseItems>((props) => ({
          purchase_items: updatePurchaseItem(props.purchase_items, item.id, {
            tracking_number: trackingNumber,
          }),
        }))
        .patch(item.tracking_update_path, {
          only: ["purchase_items"],
          preserveScroll: true,
          onBefore: () => {
            form.clearErrors();
            onClose();
          },
          onError: () => onOpen(),
          onSuccess: () => {
            form.clearErrors();
            onSaved(item.id);
          },
        });
    },
    [
      form,
      item.id,
      item.shipping_company_id,
      item.tracking_update_path,
      onClose,
      onOpen,
      onSaved,
      trackingNumber,
    ],
  );

  const changeTrackingNumber = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors();
      form.setData((data) => ({
        ...data,
        purchase_item: { tracking_number: event.target.value },
      }));
    },
    [form],
  );

  return {
    cancelEditing: () => {
      setShippingRequiredError("");
      onClose();
    },
    changeTrackingNumber,
    error,
    submitTrackingNumber,
    trackingNumber,
  };
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
