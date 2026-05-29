import type { GroupBase, Props as SelectProps } from "react-select";
import SmartSelect from "./SmartSelect";

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
    <div className={className}>
      <label htmlFor={inputId}>{label}</label>
      <SmartSelect inputId={inputId} {...props} />
      {error && <p className="text-error mt-2">{error}</p>}
    </div>
  );
}
