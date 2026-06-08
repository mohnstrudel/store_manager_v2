type Option<Value extends string | number> = {
  value: Value;
  label: string;
};

export function toSelectedOption<Value extends string | number, O extends Option<Value>>(
  options: O[],
  value: Value | null,
): O | null {
  return options.find((option) => option.value === value) ?? null;
}
