import { useForm, usePage } from "@inertiajs/react";
import type { PathHelper } from "@js-from-routes/client";
import { useCallback, useEffect, useEffectEvent, useState, type ChangeEvent } from "react";

import { replaceById } from "@/utils/replaceById";

import { useRecentlySaved } from "./useRecentlySaved";

type InlineCellFormConfig<TRecord extends { id: number }> = {
  editedRecord: TRecord;
  /** Attribute being edited, e.g. "tracking_number". Must exist on the record. */
  attributeName: keyof TRecord & string;
  /** The js-from-routes PATCH helper. Provides the URL. */
  route: PathHelper;
  /** Inertia page prop holding the collection, e.g. "purchase_items". */
  collection: string;
  /** Strong-params root key for the PATCH body, e.g. "purchase_item". */
  paramKey: string;
  /** Route param naming the record id, e.g. "purchase_item_id" or "id". */
  idParam: string;
  /** Maps the new form value to the record state for the optimistic update.
   *  Defaults to `{ [attributeName]: newValue }`. Override when the optimistic
   *  row needs extra fields or type coercion (e.g. id + display name). */
  mapNewValueToState?: (newValue: string) => Partial<TRecord>;
  /** Normalizes the submitted form value before patching and optimistic updates. */
  normalizeValueForSave?: (value: string) => string;
  /** Defaults to the current page URL. Override only when saving should return elsewhere. */
  returnTo?: string;
  /** Inertia props to reload after save. Defaults to the edited collection only. */
  reloadProps?: string[];
  /** Reads a field error. Defaults to `errors[attributeName] || errors.base`. */
  errorFrom?: (errors: Record<string, string>) => string;
  /** Side effect called when the user opens the editor (not via ref). */
  onOpen?: () => void;
};

/**
 * Drives a single editable table cell that patches one attribute via Inertia.
 *
 * Manages open state and derives the endpoint URL, strong-params key, and page
 * collection from the js-from-routes helper. Returns `open`, `close`, and
 * `openSilently` so callers don't manage their own useState / useCallback.
 * `openSilently` is for `useImperativeHandle` — it sets state without triggering
 * the `onOpen` side effect, preventing cascade when siblings open each other.
 */
export function useInlineCellForm<TRecord extends { id: number }>({
  editedRecord,
  attributeName,
  route,
  collection,
  paramKey,
  idParam,
  mapNewValueToState,
  normalizeValueForSave,
  returnTo,
  reloadProps,
  errorFrom,
  onOpen: onOpenEffect,
}: InlineCellFormConfig<TRecord>) {
  const { isSaved, markAsSaved } = useRecentlySaved();
  const page = usePage();
  const resolvedReturnTo = returnTo ?? page.url;
  const updatePath = route.path({ [idParam]: editedRecord.id });
  const resolvedMapToState: (newValue: string) => Partial<TRecord> =
    mapNewValueToState ??
    // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion -- a single-key patch is a valid Partial<TRecord> for the edited attribute
    ((newValue: string) => ({ [attributeName]: newValue }) as Partial<TRecord>);

  const [isOpen, setIsOpen] = useState(false);

  const openSilently = useCallback(() => setIsOpen(true), []);

  const open = useCallback(() => {
    setIsOpen(true);
    onOpenEffect?.();
  }, [onOpenEffect]);

  const close = useCallback(() => setIsOpen(false), []);

  const recordId = editedRecord.id;
  const persistedValue = String(editedRecord[attributeName] ?? "");
  const form = useForm({ value: persistedValue, return_to: resolvedReturnTo });

  const syncToPersistedValue = useEffectEvent(() => {
    form.setData({ value: persistedValue, return_to: resolvedReturnTo });
  });

  useEffect(() => {
    if (isOpen) return;
    syncToPersistedValue();
  }, [isOpen, persistedValue, resolvedReturnTo]);

  const readError = errorFrom ?? defaultErrorReader(attributeName);

  const onChange = (event: ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    form.clearErrors();
    form.setData((data) => ({ ...data, value: event.target.value }));
  };

  const save = () => {
    const newValue = normalizeValueForSave
      ? normalizeValueForSave(form.data.value)
      : form.data.value;
    form.transform(() => ({
      [paramKey]: { [attributeName]: newValue },
      return_to: form.data.return_to,
    }));
    form
      .optimistic<Record<string, TRecord[]>>((props) => ({
        [collection]: replaceById(props[collection], recordId, resolvedMapToState(newValue)),
      }))
      .patch(updatePath, {
        only: reloadProps ?? [collection],
        preserveScroll: true,
        onBefore: () => {
          form.clearErrors();
          close();
        },
        onError: () => open(),
        onSuccess: () => {
          form.clearErrors();
          markAsSaved();
        },
      });
  };

  return {
    isOpen,
    isSaved,
    open,
    close,
    openSilently,
    value: form.data.value,
    error: readError(form.errors),
    onChange,
    save,
  };
}

function defaultErrorReader(attributeName: string) {
  const label = attributeName.replace(/_id$/, "").replace(/_/g, " ");
  return (errors: Record<string, string>) => {
    if (Object.keys(errors).length === 0) return "";
    return errors[attributeName] || errors.base || `Could not save ${label}`;
  };
}
