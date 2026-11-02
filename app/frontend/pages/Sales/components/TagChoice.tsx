import { CheckIcon } from "@heroicons/react/16/solid";
import { useCallback, type ReactNode } from "react";

import type { SalesTagColor } from "@/types/salesTag";

import { TagBadge } from "./TagBadges";

type TagChoiceProps<Value extends string | number> = {
  checked: boolean;
  children: ReactNode;
  color: SalesTagColor;
  disabled: boolean;
  name?: string;
  onChange: (value: Value) => void;
  type: "checkbox" | "radio";
  value: Value;
};

export default function TagChoice<Value extends string | number>({
  checked,
  children,
  color,
  disabled,
  name,
  onChange,
  type,
  value,
}: TagChoiceProps<Value>) {
  const select = useCallback(() => onChange(value), [onChange, value]);

  return (
    <label className="sales_tag_choice" data-literal>
      <input
        checked={checked}
        className="sr-only"
        disabled={disabled}
        name={name}
        onChange={select}
        type={type}
        value={value}
      />
      <TagBadge color={color}>
        <span aria-hidden className="sales_tag_check">
          <CheckIcon height={12} width={12} />
        </span>
        {children}
      </TagBadge>
    </label>
  );
}
