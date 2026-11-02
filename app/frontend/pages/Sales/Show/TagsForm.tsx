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
  id: string;
  options: SalesTagRecord[];
};

export default function TagsForm({ colors, form, id, options }: TagsFormProps) {
  const [query, setQuery] = useState("");
  const colorLines = useMemo(() => groupByColor(options, colors), [options, colors]);
  const needle = query.trim().toLowerCase();
  const visibleLines = colorLines
    .map(({ color, tags }) => ({
      color,
      tags: tags.filter((tag) => tag.name.toLowerCase().includes(needle)),
    }))
    .filter((line) => line.tags.length > 0);
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
    (tagId: number) => {
      select(
        selectedIds.includes(tagId)
          ? selectedIds.filter((selectedId) => selectedId !== tagId)
          : [...selectedIds, tagId],
      );
    },
    [select, selectedIds],
  );

  return (
    <form className="flex flex-col gap-4" id={id} onSubmit={submit}>
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

      <fieldset className="mb-0 min-h-[5.5rem] max-h-[calc(100dvh-23rem)] overflow-y-auto p-1.5">
        <legend className="sr-only">Tags</legend>
        {visibleLines.length > 0 ? (
          <div className="flex flex-col gap-3">
            {visibleLines.map((line) => (
              <ul className="sales_tag_choices gap-2.5" key={line.color}>
                {line.tags.map((tag) => (
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
            ))}
          </div>
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
    </form>
  );
}

type TagsFormActionsProps = {
  form: SaleTagsForm;
  formId: string;
};

export function TagsFormActions({ form, formId }: TagsFormActionsProps) {
  return (
    <>
      <button
        className="btn_rounded btn_blue"
        disabled={form.processing}
        form={formId}
        type="submit"
      >
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
    </>
  );
}

type ColorLine = { color: SalesTagColor; tags: SalesTagRecord[] };

function groupByColor(options: SalesTagRecord[], colors: SalesTagColor[]): ColorLine[] {
  return colors
    .map((color) => ({ color, tags: sortedByName(options.filter((tag) => tag.color === color)) }))
    .filter((line) => line.tags.length > 0);
}

function sortedByName(tags: SalesTagRecord[]) {
  // oxlint-disable-next-line unicorn/no-array-sort -- callers pass a fresh array; the ES2020 lib has no toSorted
  return tags.sort(
    (a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }) || a.id - b.id,
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
        <span aria-hidden className="sales_tag_check">
          <CheckIcon height={12} width={12} />
        </span>
        {tag.name}
      </TagBadge>
    </label>
  );
}
