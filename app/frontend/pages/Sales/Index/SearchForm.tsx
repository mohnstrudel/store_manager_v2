import { router } from "@inertiajs/react";
import { useCallback, useState, type ChangeEvent, type FormEvent } from "react";

import routes from "@/utils/routes";

import type { SaleSort, SalesFilters } from "../types";
import { listingHref, listingParams, type SalesListingSettings } from "./salesListing";

type SearchFormProps = {
  q: string;
  sort: SaleSort;
  filters: SalesFilters;
};

const LISTING_PROPS = ["sales", "pagination", "search", "sort", "filters"];

const SORT_OPTIONS: { value: SaleSort; label: string }[] = [
  { value: "newest", label: "Newest first" },
  { value: "oldest", label: "Oldest first" },
];

export default function SearchForm({ q, sort, filters }: SearchFormProps) {
  const applied: SalesListingSettings = { q, sort, ...filters };
  const appliedHref = listingHref(applied);
  const [form, setForm] = useState({ appliedHref, synced: applied, draft: applied });
  const hasSearch = q !== "";
  let current = form;

  if (form.appliedHref !== appliedHref) {
    const answersSubmission = listingHref(form.synced) === appliedHref;

    current = { appliedHref, synced: applied, draft: answersSubmission ? form.draft : applied };
    setForm(current);
  }

  const { draft } = current;

  const submit = useCallback((settings: SalesListingSettings) => {
    setForm((state) => ({ ...state, synced: settings, draft: settings }));
    visitListing(settings);
  }, []);

  const handleSubmit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      submit(draft);
    },
    [draft, submit],
  );

  const handleQueryChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value;

    setForm((state) => ({ ...state, draft: { ...state.draft, q: value } }));
  }, []);

  const applyChange = useCallback(
    (change: Partial<SalesListingSettings>) => submit({ ...draft, ...change }),
    [draft, submit],
  );

  const handleClear = useCallback(() => applyChange({ q: "" }), [applyChange]);

  const handleSortSelect = useCallback(
    (value: SaleSort) => applyChange({ sort: value }),
    [applyChange],
  );

  const handleFilterToggle = useCallback(
    (name: keyof SalesFilters, checked: boolean) => applyChange({ [name]: checked }),
    [applyChange],
  );

  return (
    <form className="flex flex-col gap-3 w-full max-w-full lg:max-w-2/3" onSubmit={handleSubmit}>
      <div className="flex flex-col lg:flex-row lg:flex-wrap lg:items-center gap-2">
        <input
          aria-label="Search sales"
          className={`lg:w-auto lg:grow lg:basis-56 ${hasSearch ? "border-2" : "border"}`}
          name="q"
          onChange={handleQueryChange}
          placeholder="Find what you need..."
          suppressHydrationWarning
          type="search"
          value={draft.q}
        />
        <button className="btn_rounded" type="submit">
          <i className="icn">🔎</i>
          Search
        </button>
        {hasSearch && (
          <button className="btn_rounded btn_red" onClick={handleClear} type="button">
            <i className="icn">❎</i>
            Clear search
          </button>
        )}
      </div>
      <div className="flex flex-col sm:flex-row sm:flex-wrap sm:items-center gap-2 sm:gap-6 px-4">
        <fieldset
          aria-label="Sort sales"
          className="tab_bar tab_bar_outline shrink-0 sm:w-fit mt-0 mb-0"
        >
          {SORT_OPTIONS.map(({ value, label }) => (
            <SortTab
              key={value}
              label={label}
              onSelect={handleSortSelect}
              selected={draft.sort === value}
              value={value}
            />
          ))}
        </fieldset>
        <FilterCheckbox
          checked={draft.hide_partial_payments}
          label="Hide Partial Payments"
          name="hide_partial_payments"
          onToggle={handleFilterToggle}
        />
        <FilterCheckbox
          checked={draft.missing_purchases_only}
          label="Missing Purchases Only"
          name="missing_purchases_only"
          onToggle={handleFilterToggle}
        />
      </div>
    </form>
  );
}

type FilterCheckboxProps = {
  checked: boolean;
  label: string;
  name: keyof SalesFilters;
  onToggle: (name: keyof SalesFilters, checked: boolean) => void;
};

function FilterCheckbox({ checked, label, name, onToggle }: FilterCheckboxProps) {
  const handleChange = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => onToggle(name, event.target.checked),
    [name, onToggle],
  );

  return (
    <label className="flex items-center gap-2 whitespace-nowrap text-sm m-0 cursor-pointer">
      <input
        checked={checked}
        className="small"
        name={name}
        onChange={handleChange}
        type="checkbox"
        value="1"
      />
      {label}
    </label>
  );
}

type SortTabProps = {
  label: string;
  onSelect: (value: SaleSort) => void;
  selected: boolean;
  value: SaleSort;
};

function SortTab({ label, onSelect, selected, value }: SortTabProps) {
  const handleClick = useCallback(() => onSelect(value), [onSelect, value]);

  return (
    <button
      aria-pressed={selected}
      className="tab_btn whitespace-nowrap"
      onClick={handleClick}
      type="button"
    >
      {label}
    </button>
  );
}

function visitListing(settings: SalesListingSettings) {
  router.get(routes.sales.list.path(), listingParams(settings), {
    only: LISTING_PROPS,
    preserveState: true,
  });
}
