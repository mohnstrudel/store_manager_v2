import { Suspense, useCallback, useMemo, useRef, type KeyboardEvent } from "react";

import { SelectSkeleton } from "@/components/FormSmartSelect";
import SmartSelect from "@/components/lazySmartSelect";
import type { SalesTagRecord } from "@/types/salesTag";

import { TagBadge } from "./TagBadges";

const SELECT_FALLBACK = <SelectSkeleton />;

type TagOption = { value: number; label: string };

type TagPickerProps = {
  inputId: string;
  label: string;
  options: SalesTagRecord[];
  selectedIds: number[];
  onChange: (ids: number[]) => void;
  disabled: boolean;
  errorId?: string;
};

export default function TagPicker({
  inputId,
  label,
  options,
  selectedIds,
  onChange,
  disabled,
  errorId,
}: TagPickerProps) {
  const menuOpen = useRef(false);
  const selectedTags = useMemo(
    () => options.filter((tag) => selectedIds.includes(tag.id)),
    [options, selectedIds],
  );
  const searchableOptions = useMemo(
    () =>
      options
        .filter((tag) => !selectedIds.includes(tag.id))
        .map((tag) => ({ value: tag.id, label: tag.name })),
    [options, selectedIds],
  );

  const addTag = useCallback(
    (option: TagOption | null) => {
      if (option) onChange([...selectedIds, option.value]);
    },
    [onChange, selectedIds],
  );

  const removeTag = useCallback(
    (id: number) => onChange(selectedIds.filter((selectedId) => selectedId !== id)),
    [onChange, selectedIds],
  );

  const keepEscapeForMenu = useCallback((event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "Escape" && menuOpen.current) event.stopPropagation();
  }, []);

  const markMenuOpen = useCallback(() => {
    menuOpen.current = true;
  }, []);

  const markMenuClosed = useCallback(() => {
    menuOpen.current = false;
  }, []);

  return (
    <div className="sales_tag_picker flex flex-col gap-2">
      <label className="sr-only" htmlFor={inputId}>
        {label}
      </label>
      <Suspense fallback={SELECT_FALLBACK}>
        <SmartSelect<TagOption>
          aria-describedby={errorId}
          aria-invalid={errorId !== undefined}
          // oxlint-disable-next-line jsx-a11y/no-autofocus -- the picker mounts only after an explicit Edit action, so focus follows the user's intent
          autoFocus
          inputId={inputId}
          isDisabled={disabled}
          onChange={addTag}
          onKeyDown={keepEscapeForMenu}
          onMenuClose={markMenuClosed}
          onMenuOpen={markMenuOpen}
          options={searchableOptions}
          placeholder="Search tags…"
          value={null}
        />
      </Suspense>
      <SelectedTags disabled={disabled} onRemove={removeTag} tags={selectedTags} />
    </div>
  );
}

type SelectedTagsProps = {
  disabled: boolean;
  tags: SalesTagRecord[];
  onRemove: (id: number) => void;
};

function SelectedTags({ disabled, tags, onRemove }: SelectedTagsProps) {
  if (tags.length === 0) return null;

  return (
    <ul aria-label="Selected tags" className="sales_tag_drafts">
      {tags.map((tag) => (
        <SelectedTag disabled={disabled} key={tag.id} onRemove={onRemove} tag={tag} />
      ))}
    </ul>
  );
}

type SelectedTagProps = {
  disabled: boolean;
  tag: SalesTagRecord;
  onRemove: (id: number) => void;
};

function SelectedTag({ disabled, tag, onRemove }: SelectedTagProps) {
  const remove = useCallback(() => onRemove(tag.id), [onRemove, tag.id]);

  return (
    <li>
      <TagBadge color={tag.color}>
        {tag.name}
        <button
          aria-label={`Remove ${tag.name}`}
          className="sales_tag_remove"
          disabled={disabled}
          onClick={remove}
          type="button"
        >
          ×
        </button>
      </TagBadge>
    </li>
  );
}
