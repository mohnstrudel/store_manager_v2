import Select, { type GroupBase, type Props as SelectProps } from "react-select";
import { reactSelectStyles } from "@/utils/reactSelectStyles";

type SmartSelectProps<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
> = Omit<
  SelectProps<Option, IsMulti, Group>,
  "classNamePrefix" | "styles" | "theme" | "getOptionLabel" | "getOptionValue"
>;

export default function SmartSelect<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
>(props: SmartSelectProps<Option, IsMulti, Group>) {
  return <Select {...props} classNamePrefix="rs" styles={reactSelectStyles} />;
}
