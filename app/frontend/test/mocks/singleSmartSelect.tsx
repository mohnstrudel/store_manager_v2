import type { ChangeEvent, KeyboardEvent } from "react";

type Option = { value: number; label: string };

type SingleSmartSelectProps = {
  "aria-describedby"?: string;
  inputId?: string;
  isDisabled?: boolean;
  onChange?: (option: Option | null) => void;
  onKeyDown?: (event: KeyboardEvent<HTMLSelectElement>) => void;
  options: Option[];
  placeholder?: string;
  value: Option | null;
};

export default function SingleSmartSelect({
  "aria-describedby": describedBy,
  inputId,
  isDisabled = false,
  onChange,
  onKeyDown,
  options,
  placeholder = "",
  value,
}: SingleSmartSelectProps) {
  const handleChange = (event: ChangeEvent<HTMLSelectElement>) => {
    onChange?.(options.find((option) => String(option.value) === event.target.value) ?? null);
  };

  return (
    <select
      aria-describedby={describedBy}
      disabled={isDisabled}
      id={inputId}
      onChange={handleChange}
      onKeyDown={onKeyDown}
      value={value ? String(value.value) : ""}
    >
      <option value="">{placeholder}</option>
      {options.map((option) => (
        <option key={option.value} value={String(option.value)}>
          {option.label}
        </option>
      ))}
    </select>
  );
}
