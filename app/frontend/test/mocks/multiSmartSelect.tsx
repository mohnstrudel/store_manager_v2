import type { ChangeEvent, KeyboardEvent } from "react";

type Option = { value: number; label: string };

type MultiSmartSelectProps = {
  "aria-describedby"?: string;
  inputId?: string;
  isDisabled?: boolean;
  onChange?: (options: Option[]) => void;
  onKeyDown?: (event: KeyboardEvent<HTMLSelectElement>) => void;
  options: Option[];
  value: Option[];
};

export default function MultiSmartSelect({
  "aria-describedby": describedBy,
  inputId,
  isDisabled = false,
  onChange,
  onKeyDown,
  options,
  value,
}: MultiSmartSelectProps) {
  const handleChange = (event: ChangeEvent<HTMLSelectElement>) => {
    const chosen = new Set(Array.from(event.target.selectedOptions, (element) => element.value));
    onChange?.(options.filter((option) => chosen.has(String(option.value))));
  };

  return (
    <select
      aria-describedby={describedBy}
      disabled={isDisabled}
      id={inputId}
      multiple
      onChange={handleChange}
      onKeyDown={onKeyDown}
      value={value.map((option) => String(option.value))}
    >
      {options.map((option) => (
        <option key={option.value} value={String(option.value)}>
          {option.label}
        </option>
      ))}
    </select>
  );
}
