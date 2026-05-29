type FormFieldProps = {
  defaultValue?: string | number;
  error?: string;
  label: string;
  name: string;
  step?: string;
  type?: "text" | "url" | "email" | "number";
};

export default function FormField({
  defaultValue = "",
  error,
  label,
  name,
  step,
  type = "text",
}: FormFieldProps) {
  const id = name.replace(/\[|\]/g, "_").replace(/_+$/g, "");

  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input
        aria-describedby={error ? `${id}_error` : undefined}
        aria-invalid={!!error}
        defaultValue={defaultValue}
        id={id}
        name={name}
        step={step}
        type={type}
      />
      {error && (
        <p className="mt-2 text-sm font-semibold text-red-700 dark:text-red-300" id={`${id}_error`}>
          {error}
        </p>
      )}
    </>
  );
}
