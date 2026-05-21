import CreatableSelect, {
  type CreatableProps,
} from "react-select/creatable";
import { type GroupBase, type StylesConfig } from "react-select";
import { reactSelectStyles } from "./SmartSelect";

type TagSelectProps<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
> = Omit<
  CreatableProps<Option, IsMulti, Group>,
  "classNamePrefix" | "styles" | "theme" | "getOptionLabel" | "getOptionValue"
>;

export default function TagSelect<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
>(props: TagSelectProps<Option, IsMulti, Group>) {
  return (
    <CreatableSelect
      {...props}
      classNamePrefix="rs"
      styles={reactSelectStyles as StylesConfig<Option, IsMulti, Group>}
    />
  );
}
