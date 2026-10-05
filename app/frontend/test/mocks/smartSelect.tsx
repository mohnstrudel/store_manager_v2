type AnyOption = { value: string | number; label: string };

const EMPTY_OPTIONS: AnyOption[] = [];

type SmartSelectProps = {
  defaultValue?: AnyOption | AnyOption[] | null;
  inputId?: string;
  isClearable?: boolean;
  isDisabled?: boolean;
  isMulti?: boolean;
  label?: string;
  name?: string;
  onChange?: (option: AnyOption | null) => void;
  options?: AnyOption[];
  value?: AnyOption | null;
};

export default function SmartSelect({
  defaultValue = null,
  inputId,
  isClearable = false,
  isDisabled = false,
  isMulti = false,
  label,
  name,
  onChange,
  options = EMPTY_OPTIONS,
  value,
}: SmartSelectProps) {
  const isControlled = value !== undefined;

  const handleChange = (e: { target: HTMLSelectElement }) => {
    const opt = options.find((o) => String(o.value) === e.target.value) ?? null;
    onChange?.(opt);
  };

  const defaultValues = Array.isArray(defaultValue)
    ? defaultValue.map((o) => String(o.value))
    : defaultValue != null
      ? [String(defaultValue.value)]
      : [];

  const hiddenValue = isControlled ? String(value?.value ?? "") : (defaultValues[0] ?? "");

  return (
    <>
      {name &&
        (isMulti ? (
          defaultValues.length > 0 ? (
            defaultValues.map((v) => <input key={v} name={name} type="hidden" value={v} />)
          ) : (
            <input name={name} type="hidden" value="" />
          )
        ) : (
          <input name={name} type="hidden" value={hiddenValue} />
        ))}
      <select
        aria-label={label}
        data-testid={inputId ?? name}
        disabled={isDisabled}
        id={inputId}
        multiple={isMulti}
        {...(isControlled
          ? { value: String(value?.value ?? ""), onChange: handleChange }
          : {
              defaultValue: isMulti ? defaultValues : (defaultValues[0] ?? ""),
              onChange: onChange ? handleChange : undefined,
            })}
      >
        {isClearable && <option value="">—</option>}
        {options.map((o) => (
          <option key={String(o.value)} value={String(o.value)}>
            {o.label}
          </option>
        ))}
      </select>
    </>
  );
}
