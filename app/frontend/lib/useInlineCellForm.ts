import { useForm } from "@inertiajs/react";
import { useEffect, useEffectEvent, type ChangeEvent } from "react";
import { replaceById } from "./replaceById";

type InlineCellFormConfig<TRecord extends { id: number }> = {
  isOpen: boolean;
  /** Row being edited; the initial value and id are read from it. */
  record: TRecord;
  /** Attribute being edited, e.g. "tracking_number". Must exist on the record. */
  field: keyof TRecord & string;
  returnTo: string;
  updatePath: string;
  /** Strong-params wrapper key, e.g. "purchase_item". */
  param: string;
  /** Page prop holding the rows to update, e.g. "purchase_items". */
  collection: string;
  /** Optimistic change applied to the row while the request is in flight. */
  toRecordPatch: (value: string) => Partial<TRecord>;
  /** Reads a field error. Defaults to `errors[field] || errors.base`. */
  errorFrom?: (errors: Record<string, string>) => string;
  onClose: () => void;
  onOpen: () => void;
  onSaved: () => void;
};

/**
 * Drives a single editable table cell that patches one field via Inertia.
 *
 * Bakes in the conventions every inline cell follows: the form starts from
 * `record[field]`, the request payload is `{ [param]: { [field]: value },
 * return_to }`, and the optimistic update replaces that record inside one page
 * collection. The caller only describes the field-specific bits — the optimistic
 * change and, when a field needs more than its own error, a custom error reader.
 */
export function useInlineCellForm<TRecord extends { id: number }>({
  collection,
  errorFrom,
  field,
  isOpen,
  onClose,
  onOpen,
  onSaved,
  param,
  record,
  returnTo,
  toRecordPatch,
  updatePath,
}: InlineCellFormConfig<TRecord>) {
  const recordId = record.id;
  const persistedValue = String(record[field] ?? "");
  const form = useForm({ value: persistedValue, return_to: returnTo });

  const syncToPersistedValue = useEffectEvent(() => {
    form.setData({ value: persistedValue, return_to: returnTo });
  });

  useEffect(() => {
    if (isOpen) return;
    syncToPersistedValue();
  }, [isOpen, persistedValue, returnTo]);

  const readError = errorFrom ?? defaultErrorReader(field);

  const onChange = (event: ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const nextValue = event.target.value;
    form.clearErrors();
    form.setData((data) => ({ ...data, value: nextValue }));
  };

  const save = () => {
    const editedValue = form.data.value;
    form.transform(() => ({
      [param]: { [field]: editedValue },
      return_to: form.data.return_to,
    }));
    form
      .optimistic<Record<string, TRecord[]>>((props) => ({
        [collection]: replaceById(props[collection], recordId, toRecordPatch(editedValue)),
      }))
      .patch(updatePath, {
        only: [collection],
        preserveScroll: true,
        onBefore: () => {
          form.clearErrors();
          onClose();
        },
        onError: () => onOpen(),
        onSuccess: () => {
          form.clearErrors();
          onSaved();
        },
      });
  };

  return {
    value: form.data.value,
    error: readError(form.errors),
    onChange,
    save,
  };
}

function defaultErrorReader(field: string) {
  const label = field.replace(/_id$/, "").replace(/_/g, " ");
  return (errors: Record<string, string>) => {
    if (Object.keys(errors).length === 0) return "";
    return errors[field] || errors.base || `Could not save ${label}`;
  };
}
