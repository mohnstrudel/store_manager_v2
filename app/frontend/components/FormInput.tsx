type FormInputProps = {
  className?: string;
  defaultValue?: string | number;
  error?: string;
  label: string;
  min?: string | number;
  name: string;
  placeholder?: string;
  step?: string;
  type?: "text" | "url" | "email" | "number";
};

export default function FormInput({
  className = "",
  defaultValue = "",
  error,
  label,
  min,
  name,
  placeholder,
  step,
  type = "text",
}: FormInputProps) {
  const id = name.replace(/\[|\]/g, "_").replace(/_+$/g, "");

  return (
    <div className={className}>
      <label htmlFor={id}>{label}</label>
      <input
        aria-describedby={error ? `${id}_error` : undefined}
        aria-invalid={!!error}
        defaultValue={defaultValue}
        id={id}
        min={min}
        name={name}
        placeholder={placeholder}
        step={step}
        type={type}
      />
      {error && (
        <p className="text-error mt-2" id={`${id}_error`}>
          {error}
        </p>
      )}
    </div>
  );
}
