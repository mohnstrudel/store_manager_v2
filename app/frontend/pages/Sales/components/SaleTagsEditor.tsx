import { useCallback, type FormEvent, type KeyboardEvent } from "react";

import FormError from "@/components/FormError";
import type { SalesTagRecord } from "@/types/salesTag";
import { stopRowNavigation } from "@/utils/rowNavigation";

import TagPicker from "./TagPicker";
import type { SaleTagsForm } from "./useSaleTagsForm";

type SaleTagsEditorProps = {
  form: SaleTagsForm;
  idPrefix: string;
  options: SalesTagRecord[];
};

export default function SaleTagsEditor({ form, idPrefix, options }: SaleTagsEditorProps) {
  const errorId = `${idPrefix}-error`;

  const submit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      form.save();
    },
    [form],
  );

  const handleKeyDown = useCallback(
    (event: KeyboardEvent<HTMLFormElement>) => {
      event.stopPropagation();
      if (event.key === "Escape" && !form.processing) form.cancel();
    },
    [form],
  );

  return (
    // oxlint-disable-next-line jsx-a11y/no-noninteractive-element-interactions -- keeps editor events away from the row
    <form
      className="flex flex-col gap-2"
      onAuxClick={stopRowNavigation}
      onClick={stopRowNavigation}
      onKeyDown={handleKeyDown}
      onSubmit={submit}
    >
      <TagPicker
        disabled={form.processing}
        errorId={form.error ? errorId : undefined}
        inputId={`${idPrefix}-picker`}
        label="Tags"
        onChange={form.select}
        options={options}
        selectedIds={form.selectedIds}
      />
      <FormError id={errorId}>{form.error}</FormError>
      {form.needsReload ? (
        <button className="btn_rounded btn_xs self-center" onClick={form.reload} type="button">
          Reload tags (discards your changes)
        </button>
      ) : null}
      <div className="flex gap-1 justify-center">
        <button className="btn_rounded btn_xs btn_green" disabled={form.processing} type="submit">
          {form.processing ? "Saving…" : "Save"}
        </button>
        <button
          className="btn_red btn_xs btn_rounded"
          disabled={form.processing}
          onClick={form.cancel}
          type="button"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
