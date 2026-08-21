import { Suspense } from "react";
import type { Props as SelectProps } from "react-select";

import FormControl from "./FormControl";
import SmartSelect from "./lazySmartSelect";

const SELECT_FALLBACK = <SelectSkeleton />;

type FormSmartSelectProps<Option, IsMulti extends boolean = false> = Omit<
  SelectProps<Option, IsMulti>,
  "classNamePrefix" | "styles" | "theme" | "getOptionLabel" | "getOptionValue" | "inputId"
> & {
  className?: string;
  error?: string;
  inputId: string;
  label: string;
};

export default function FormSmartSelect<Option, IsMulti extends boolean = false>({
  className = "",
  error,
  inputId,
  label,
  ...props
}: FormSmartSelectProps<Option, IsMulti>) {
  return (
    <FormControl className={className} error={error} htmlFor={inputId} label={label}>
      <Suspense fallback={SELECT_FALLBACK}>
        <SmartSelect
          aria-describedby={error ? `${inputId}_error` : undefined}
          aria-invalid={!!error}
          inputId={inputId}
          {...props}
        />
      </Suspense>
    </FormControl>
  );
}

export function SelectSkeleton() {
  return (
    <div className="h-10 w-full rounded border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 animate-pulse" />
  );
}
