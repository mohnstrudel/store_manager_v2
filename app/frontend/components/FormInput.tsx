import FormControl from "./FormControl";

type FormInputProps = {
  autoComplete?: string;
  autoFocus?: boolean;
  className?: string;
  defaultValue?: string | number;
  error?: string;
  label: string;
  maxLength?: number;
  min?: string | number;
  name: string;
  placeholder?: string;
  required?: boolean;
  step?: string;
  type?: "text" | "url" | "email" | "number" | "password";
};

export default function FormInput({
  autoComplete,
  autoFocus,
  className = "",
  defaultValue = "",
  error,
  label,
  maxLength,
  min,
  name,
  placeholder,
  required,
  step,
  type = "text",
}: FormInputProps) {
  const id = name.replace(/\[|\]/g, "_").replace(/_+$/g, "");

  return (
    <FormControl className={className} error={error} htmlFor={id} label={label}>
      <input
        aria-describedby={error ? `${id}_error` : undefined}
        aria-invalid={!!error}
        autoComplete={autoComplete}
        autoFocus={autoFocus}
        defaultValue={defaultValue}
        id={id}
        maxLength={maxLength}
        min={min}
        name={name}
        placeholder={placeholder}
        required={required}
        step={step}
        type={type}
      />
    </FormControl>
  );
}
