type FormFieldProps = {
  error?: string[];
  label: string;
  name: string;
  onChange: (value: string) => void;
  value: string;
};

export default function FormField({ error = [], label, name, onChange, value }: FormFieldProps) {
  const inputId = `size_${name}`;

  return (
    <fieldset>
      <label htmlFor={inputId}>{label}</label>
      <input
        aria-invalid={error.length > 0}
        aria-describedby={error.length > 0 ? `${inputId}_error` : undefined}
        id={inputId}
        name={`size[${name}]`}
        onChange={(event) => onChange(event.target.value)}
        type="text"
        value={value}
      />
      {error.length > 0 ? (
        <p className="mt-2 text-sm font-semibold text-red-700 dark:text-red-300" id={`${inputId}_error`}>
          {error.join(", ")}
        </p>
      ) : null}
    </fieldset>
  );
}
