import { CheckIcon } from "@heroicons/react/16/solid";
import {
  useCallback,
  useMemo,
  useState,
  type ChangeEvent,
  type KeyboardEvent,
  type SubmitEvent,
} from "react";

import FormError from "@/components/FormError";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import { TagBadge } from "../components/TagBadges";
import type { SaleTagsForm } from "../components/useSaleTagsForm";

type TagsFormProps = {
  colors: SalesTagColor[];
  form: SaleTagsForm;
  options: SalesTagRecord[];
};

export default function TagsForm({ colors, form, options }: TagsFormProps) {
  const [query, setQuery] = useState("");
  const groupedOptions = useMemo(() => groupByColor(options, colors), [options, colors]);
  const needle = query.trim().toLowerCase();
  const visibleOptions = groupedOptions.filter((tag) => tag.name.toLowerCase().includes(needle));
  const { save, select, selectedIds } = form;

  const submit = useCallback(
    (event: SubmitEvent<HTMLFormElement>) => {
      event.preventDefault();
      save();
    },
    [save],
  );

  const filter = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setQuery(event.target.value);
  }, []);

  const keepEnterFromSaving = useCallback((event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "Enter") event.preventDefault();
  }, []);

  const toggle = useCallback(
    (id: number) => {
      select(
        selectedIds.includes(id)
          ? selectedIds.filter((selectedId) => selectedId !== id)
          : [...selectedIds, id],
      );
    },
    [select, selectedIds],
  );

  return (
    <form className="flex flex-col gap-4" onSubmit={submit}>
      <input
        aria-label="Filter tags"
        autoFocus // oxlint-disable-line jsx-a11y/no-autofocus -- the form mounts inside a modal the user just opened
        disabled={form.processing}
        onChange={filter}
        onKeyDown={keepEnterFromSaving}
        placeholder="Filter tags…"
        type="search"
        value={query}
      />

      <fieldset className="mb-0 min-h-[4.5rem] max-h-64 overflow-y-auto p-1">
        <legend className="sr-only">Tags</legend>
        {visibleOptions.length > 0 ? (
          <ul className="sales_tag_choices">
            {visibleOptions.map((tag) => (
              <li key={tag.id}>
                <TagChoice
                  checked={selectedIds.includes(tag.id)}
                  disabled={form.processing}
                  onToggle={toggle}
                  tag={tag}
                />
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-gray-500 dark:text-gray-400">No tags match “{query.trim()}”.</p>
        )}
      </fieldset>

      <FormError>{form.error}</FormError>
      {form.needsReload ? (
        <button className="btn_rounded w-fit" onClick={form.reload} type="button">
          Reload tags (discards your changes)
        </button>
      ) : null}

      <div className="flex gap-2">
        <button className="btn_rounded btn_blue" disabled={form.processing} type="submit">
          {form.processing ? "Saving…" : "Save"}
        </button>
        <button
          className="btn_rounded"
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

function groupByColor(options: SalesTagRecord[], colors: SalesTagColor[]) {
  // oxlint-disable-next-line unicorn/no-array-sort -- sorts a fresh copy; the ES2020 lib has no toSorted
  return [...options].sort(
    (a, b) =>
      colors.indexOf(a.color) - colors.indexOf(b.color) ||
      a.name.localeCompare(b.name, undefined, { sensitivity: "base" }) ||
      a.id - b.id,
  );
}

type TagChoiceProps = {
  checked: boolean;
  disabled: boolean;
  onToggle: (id: number) => void;
  tag: SalesTagRecord;
};

function TagChoice({ checked, disabled, onToggle, tag }: TagChoiceProps) {
  const { id } = tag;
  const toggle = useCallback(() => onToggle(id), [onToggle, id]);

  return (
    <label className="sales_tag_choice" data-literal>
      <input
        checked={checked}
        className="sr-only"
        disabled={disabled}
        onChange={toggle}
        type="checkbox"
      />
      <TagBadge color={tag.color}>
        <CheckIcon aria-hidden className={checked ? "" : "invisible"} height={12} width={12} />
        {tag.name}
      </TagBadge>
    </label>
  );
}
