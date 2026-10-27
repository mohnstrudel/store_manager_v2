import { Suspense, useCallback, useMemo, useRef, type KeyboardEvent } from "react";

import { SelectSkeleton } from "@/components/FormSmartSelect";
import SmartSelect from "@/components/lazySmartSelect";
import type { SalesTagRecord } from "@/types/salesTag";

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
  const tagOptions = useMemo(
    () => options.map((tag) => ({ value: tag.id, label: tag.name })),
    [options],
  );
  const selected = useMemo(
    () => tagOptions.filter((option) => selectedIds.includes(option.value)),
    [tagOptions, selectedIds],
  );

  const changeSelection = useCallback(
    (next: readonly TagOption[]) => onChange(next.map((option) => option.value)),
    [onChange],
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
    <div className="sales_tag_picker">
      <label className="sr-only" htmlFor={inputId}>
        {label}
      </label>
      <Suspense fallback={SELECT_FALLBACK}>
        <SmartSelect<TagOption, true>
          aria-describedby={errorId}
          aria-invalid={errorId !== undefined}
          // oxlint-disable-next-line jsx-a11y/no-autofocus -- the picker mounts only after an explicit Edit action, so focus follows the user's intent
          autoFocus
          inputId={inputId}
          isDisabled={disabled}
          isMulti
          onChange={changeSelection}
          onKeyDown={keepEscapeForMenu}
          onMenuClose={markMenuClosed}
          onMenuOpen={markMenuOpen}
          options={tagOptions}
          placeholder="Search tags…"
          value={selected}
        />
      </Suspense>
    </div>
  );
}
