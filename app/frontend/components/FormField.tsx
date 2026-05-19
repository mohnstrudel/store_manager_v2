type FormFieldProps = {
  error?: string[];
  label: string;
  name: string;
  namespace: string;
  onChange: (value: string) => void;
  type?: "text" | "url" | "email";
  value: string;
};

export default function FormField({
  error = [],
  label,
  name,
  namespace,
  onChange,
  type = "text",
  value,
}: FormFieldProps) {
  const inputId = `${namespace}_${name}`;

  return (
    <fieldset>
      <label htmlFor={inputId}>{label}</label>
      <input
        aria-invalid={error.length > 0}
        aria-describedby={error.length > 0 ? `${inputId}_error` : undefined}
        id={inputId}
        name={`${namespace}[${name}]`}
        onChange={(event) => onChange(event.target.value)}
        type={type}
        value={value}
      />
      {error.length > 0 ? (
        <p
          className="mt-2 text-sm font-semibold text-red-700 dark:text-red-300"
          id={`${inputId}_error`}
        >
          {error.join(", ")}
        </p>
      ) : null}
    </fieldset>
  );
}
