import CreatableSelect, { type CreatableProps } from "react-select/creatable";
import { type GroupBase } from "react-select";
import { reactSelectStyles } from "@/utils/reactSelectStyles";

type TagSelectProps<Option, IsMulti extends boolean = false> = Omit<
  CreatableProps<Option, IsMulti, GroupBase<Option>>,
  "classNamePrefix" | "styles" | "theme" | "getOptionLabel" | "getOptionValue"
>;

const tagSelectClassNames = {
  control: () => "!h-auto",
  valueContainer: () => "!flex-wrap !overflow-visible !h-auto !items-start !p-2 !gap-1",
};

export default function TagSelect<Option, IsMulti extends boolean = false>(
  props: TagSelectProps<Option, IsMulti>,
) {
  return (
    <CreatableSelect
      {...props}
      classNamePrefix="rs"
      styles={reactSelectStyles}
      classNames={tagSelectClassNames}
    />
  );
}
