import Select, { type Props as SelectProps } from "react-select";
import { reactSelectStyles } from "@/utils/reactSelectStyles";

type SmartSelectProps<Option, IsMulti extends boolean = false> = Omit<
  SelectProps<Option, IsMulti>,
  "classNamePrefix" | "styles" | "theme" | "getOptionLabel" | "getOptionValue"
>;

export default function SmartSelect<Option, IsMulti extends boolean = false>(
  props: SmartSelectProps<Option, IsMulti>,
) {
  return <Select {...props} classNamePrefix="rs" styles={reactSelectStyles} />;
}
