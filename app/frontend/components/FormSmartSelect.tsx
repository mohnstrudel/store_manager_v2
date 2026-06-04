import { lazy, Suspense } from "react";
import type { GroupBase, Props as SelectProps } from "react-select";
import FormControl from "./FormControl";

const SmartSelect = lazy(() => import("./SmartSelect"));
const SELECT_FALLBACK = <SelectSkeleton />;

type FormSmartSelectProps<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
> = Omit<
  SelectProps<Option, IsMulti, Group>,
  "classNamePrefix" | "styles" | "theme" | "getOptionLabel" | "getOptionValue" | "inputId"
> & {
  className?: string;
  error?: string;
  inputId: string;
  label: string;
};

export default function FormSmartSelect<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
>({
  className = "",
  error,
  inputId,
  label,
  ...props
}: FormSmartSelectProps<Option, IsMulti, Group>) {
  return (
    <FormControl className={className} error={error} htmlFor={inputId} label={label}>
      <Suspense fallback={SELECT_FALLBACK}>
        <SmartSelect
          aria-describedby={error ? `${inputId}_error` : undefined}
          aria-invalid={!!error}
          inputId={inputId}
          {...(props as any)}
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
