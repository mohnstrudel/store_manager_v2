import { useForm } from "@inertiajs/react";
import {
  useCallback,
  type ChangeEvent,
  useEffect,
  useEffectEvent,
  type FormEvent,
} from "react";
import FormError from "@/components/FormError";
import type { ShippingCompanyOption, WarehousePurchaseItemRecord } from "../types";
import {
  InlineEditorActions,
  stopInlineEditorNavigation,
  updatePurchaseItem,
} from "./InlineEditorActions";

type ShippingCompanyEditorProps = {
  item: WarehousePurchaseItemRecord;
  isOpen: boolean;
  onClose: () => void;
  onOpen: () => void;
  onSaved: (itemId: number) => void;
  returnTo: string;
  shippingCompanies: ShippingCompanyOption[];
};

type WithPurchaseItems = { purchase_items: WarehousePurchaseItemRecord[] };

export function InlineShippingCompanyEditor({
  item,
  isOpen,
  onClose,
  onOpen,
  onSaved,
  returnTo,
  shippingCompanies,
}: ShippingCompanyEditorProps) {
  const editor = useShippingCompanyEditor({
    item,
    isOpen,
    onClose,
    onOpen,
    onSaved,
    returnTo,
    shippingCompanies,
  });

  if (isOpen) {
    return (
      <form
        className="flex flex-col w-full gap-2 no_events"
        onAuxClick={stopInlineEditorNavigation}
        onClick={stopInlineEditorNavigation}
        onKeyDown={stopInlineEditorNavigation}
        onSubmit={editor.submitShippingCompany}
      >
        <label className="sr-only" htmlFor={`purchase_item_${item.id}_shipping_company_id`}>
          Shipping company
        </label>
        <select
          autoFocus
          className="border rounded px-2 py-1 text-sm w-full min-w-35"
          id={`purchase_item_${item.id}_shipping_company_id`}
          onChange={editor.changeShippingCompany}
          value={editor.shippingCompanyId}
        >
          <option value="">Select a shipping company</option>
          {shippingCompanies.map((shippingCompany) => (
            <option key={shippingCompany.id} value={shippingCompany.id}>
              {shippingCompany.name}
            </option>
          ))}
        </select>
        <FormError>{editor.error}</FormError>
        <InlineEditorActions onCancel={onClose} />
      </form>
    );
  }

  return (
    <InlineShippingCompanyDisplay
      shippingCompanyName={item.shipping_company_name}
      onEdit={onOpen}
    />
  );
}

function InlineShippingCompanyDisplay({
  shippingCompanyName,
  onEdit,
}: {
  shippingCompanyName: string;
  onEdit: () => void;
}) {
  return (
    <div
      className="flex flex-col items-center gap-2 text-center"
      onAuxClick={stopInlineEditorNavigation}
      onClick={stopInlineEditorNavigation}
      onKeyDown={stopInlineEditorNavigation}
    >
      {shippingCompanyName && <div>{shippingCompanyName}</div>}
      <button className="btn_xs btn_rounded no_events" onClick={onEdit} type="button">
        {shippingCompanyName ? "Edit" : "Add"}
      </button>
    </div>
  );
}

function useShippingCompanyEditor({
  item,
  isOpen,
  onClose,
  onOpen,
  onSaved,
  returnTo,
  shippingCompanies,
}: ShippingCompanyEditorProps) {
  const form = useForm({
    purchase_item: {
      shipping_company_id: item.shipping_company_id ? String(item.shipping_company_id) : "",
    },
    return_to: returnTo,
  });

  const shippingCompanyId = form.data.purchase_item.shipping_company_id;
  const error = shippingCompanyError(form.errors);
  const selectedShippingCompany = shippingCompanies.find(
    (shippingCompany) => String(shippingCompany.id) === shippingCompanyId,
  );
  const syncShippingCompanyForm = useEffectEvent(
    (nextShippingCompanyId: string, nextReturnTo: string) => {
      form.setData({
        purchase_item: { shipping_company_id: nextShippingCompanyId },
        return_to: nextReturnTo,
      });
    },
  );

  useEffect(() => {
    if (isOpen) return undefined;

    syncShippingCompanyForm(
      item.shipping_company_id ? String(item.shipping_company_id) : "",
      returnTo,
    );
    return undefined;
  }, [isOpen, item.shipping_company_id, returnTo]);

  const submitShippingCompany = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      form
        .optimistic<WithPurchaseItems>((props) => ({
          purchase_items: updatePurchaseItem(props.purchase_items, item.id, {
            shipping_company_id: shippingCompanyId ? Number(shippingCompanyId) : null,
            shipping_company_name: selectedShippingCompany?.name || "",
          }),
        }))
        .patch(item.shipping_company_update_path, {
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
      item.shipping_company_update_path,
      onClose,
      onOpen,
      onSaved,
      selectedShippingCompany?.name,
      shippingCompanyId,
    ],
  );

  const changeShippingCompany = useCallback(
    (event: ChangeEvent<HTMLSelectElement>) => {
      form.clearErrors();
      form.setData((data) => ({
        ...data,
        purchase_item: { shipping_company_id: event.target.value },
      }));
    },
    [form],
  );

  return {
    changeShippingCompany,
    error,
    shippingCompanyId,
    submitShippingCompany,
  };
}

function shippingCompanyError(errors: Record<string, string>) {
  if (Object.keys(errors).length === 0) return "";

  return errors.shipping_company_id || errors.base || "Could not save shipping company";
}
