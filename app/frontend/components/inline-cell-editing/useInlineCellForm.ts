import { useForm, usePage } from "@inertiajs/react";
import type { PathHelper } from "@js-from-routes/client";
import { useCallback, useEffect, useEffectEvent, useState, type ChangeEvent } from "react";

import { replaceById } from "@/utils/replaceById";

import { useRecentlySaved } from "./useRecentlySaved";

type InlineCellFormConfig<TRecord extends { id: number }> = {
  editedRecord: TRecord;
  attributeName: keyof TRecord & string;
  route: PathHelper;
  collection: string;
  paramKey: string;
  idParam: string;
  mapNewValueToState?: (newValue: string) => Partial<TRecord>;
  normalizeValueForSave?: (value: string) => string;
  returnTo?: string;
  reloadProps?: string[];
  errorFrom?: (errors: Record<string, string>) => string;
  onOpen?: () => void;
};

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
