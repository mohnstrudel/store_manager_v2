import type { PathHelper } from "@js-from-routes/client";
import { useForm, usePage } from "@inertiajs/react";
import { useCallback, useEffect, useEffectEvent, useState, type ChangeEvent } from "react";
import { replaceById } from "./replaceById";
import { useRecentlySaved } from "./useRecentlySaved";

type InlineCellFormConfig<TRecord extends { id: number }> = {
  editedRecord: TRecord;
  /** Attribute being edited, e.g. "tracking_number". Must exist on the record. */
  attributeName: keyof TRecord & string;
  /** The js-from-routes PATCH helper. Provides the URL, param key, and collection name. */
  route: PathHelper;
  /** Maps the new form value to the record state for the optimistic update.
   *  Defaults to `{ [attributeName]: newValue }`. Override when the optimistic
   *  row needs extra fields or type coercion (e.g. id + display name). */
  mapNewValueToState?: (newValue: string) => Partial<TRecord>;
  /** Defaults to the current page URL. Override only when saving should return elsewhere. */
  returnTo?: string;
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
  mapNewValueToState,
  returnTo,
  errorFrom,
  onOpen: onOpenEffect,
}: InlineCellFormConfig<TRecord>) {
  const { isSaved, markAsSaved } = useRecentlySaved();
  const page = usePage();
  const resolvedReturnTo = returnTo ?? page.url;
  const { collection, param, idParamName } = parseRoute(route.pathTemplate);
  const updatePath = route.path({ [idParamName]: editedRecord.id });
  const resolvedMapToState: (newValue: string) => Partial<TRecord> =
    mapNewValueToState ??
    ((newValue: string): any => Object.fromEntries([[attributeName, newValue]]));

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
    const newValue = form.data.value;
    form.transform(() => ({
      [param]: { [attributeName]: newValue },
      return_to: form.data.return_to,
    }));
    form
      .optimistic<Record<string, TRecord[]>>((props) => ({
        [collection]: replaceById(props[collection], recordId, resolvedMapToState(newValue)),
      }))
      .patch(updatePath, {
        only: [collection],
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

function parseRoute(pathTemplate: string) {
  const parts = pathTemplate.split("/").filter(Boolean);
  const collection = parts[0];
  const namedIdPart = parts.find((p) => p.startsWith(":") && p.endsWith("_id"));
  if (namedIdPart) {
    const idParamName = namedIdPart.slice(1);
    return { collection, param: idParamName.replace(/_id$/, ""), idParamName };
  }
  const param = collection.replace(/s$/, "");
  return { collection, param, idParamName: "id" };
}

function defaultErrorReader(attributeName: string) {
  const label = attributeName.replace(/_id$/, "").replace(/_/g, " ");
  return (errors: Record<string, string>) => {
    if (Object.keys(errors).length === 0) return "";
    return errors[attributeName] || errors.base || `Could not save ${label}`;
  };
}
