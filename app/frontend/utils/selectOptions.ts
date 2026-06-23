type Option<Value extends string | number> = {
  value: Value;
  label: string;
};

export function toSelectedOption<Value extends string | number>(
  options: Option<Value>[],
  value: Value | null,
): Option<Value> | null {
  return options.find((option) => option.value === value) ?? null;
}
