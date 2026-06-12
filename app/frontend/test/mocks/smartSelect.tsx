// Canonical test double for "@/components/SmartSelect".
//
// Activate per test file with:
//   vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));
//
// If the component under test uses SmartSelect only through FormSmartSelect
// (i.e. no direct SmartSelect import in the component file), add a side-effect
// import BEFORE vi.mock to prime the module cache for React.lazy resolution:
//   import "@/components/SmartSelect";
//   vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));
//
// Renders a native <select> so tests can interact with standard HTML:
//   - id={inputId} — enables <label htmlFor> associations (getByLabelText)
//   - data-testid={inputId ?? name} — for direct testid queries
//   - hidden <input name> — for form-submission assertions via querySelector
//   - onChange fires with the matching option object (or null for empty value)
//   - Controlled (value prop) and uncontrolled (defaultValue prop) modes
//   - isMulti, isDisabled, isClearable passthrough

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
