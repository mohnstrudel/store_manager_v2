import Select, { type GroupBase, type Props as SelectProps, type StylesConfig } from "react-select";

type SmartSelectProps<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
> = Omit<
  SelectProps<Option, IsMulti, Group>,
  "classNamePrefix" | "styles" | "theme" | "getOptionLabel" | "getOptionValue"
>;

export const reactSelectStyles: StylesConfig<unknown, boolean, GroupBase<unknown>> = {
  control: (base, state) => ({
    ...base,
    boxSizing: "border-box",
    borderStyle: "solid",
    borderWidth: 1,
    minHeight: 40,
    height: 40,
    borderRadius: 4,
    borderColor: "var(--react-select-border)",
    backgroundColor: state.isDisabled
      ? "var(--react-select-disabled-bg)"
      : "var(--react-select-bg)",
    boxShadow: "none",
    cursor: state.isDisabled ? "not-allowed" : state.isMulti ? "text" : "pointer",
    padding: 0,
    outline: state.isFocused ? "2px dashed var(--react-select-outline)" : "none",
    outlineOffset: state.isFocused ? "2px" : 0,
    transition: "border-color 150ms, outline-color 150ms",
    "&:hover": {
      borderColor: "var(--react-select-border)",
    },
  }),
  valueContainer: (base, state) => ({
    ...base,
    minWidth: 0,
    padding: state.isMulti ? "0 8px" : "0 12px",
    height: "100%",
    alignItems: "center",
    alignContent: "center",
    gap: state.isMulti ? 3 : 0,
    overflowX: state.isMulti ? "auto" : "hidden",
    overflowY: "hidden",
    flexWrap: "nowrap",
    scrollbarWidth: "none",
    msOverflowStyle: "none",
    "&::-webkit-scrollbar": {
      display: "none",
    },
  }),
  input: (base) => ({
    ...base,
    margin: 0,
    padding: 0,
    color: "var(--react-select-text)",
  }),
  placeholder: (base) => ({
    ...base,
    margin: 0,
    color: "var(--react-select-placeholder)",
  }),
  singleValue: (base, state) => ({
    ...base,
    margin: 0,
    color: state.isDisabled ? "var(--react-select-disabled-text)" : "var(--react-select-text)",
  }),
  indicatorsContainer: (base) => ({
    ...base,
    alignSelf: "center",
    alignItems: "center",
    display: "flex",
    height: "100%",
    justifyContent: "center",
  }),
  clearIndicator: (base, state) => ({
    ...base,
    alignItems: "center",
    alignSelf: "center",
    color: state.isFocused ? "var(--react-select-text)" : "var(--react-select-muted)",
    cursor: state.selectProps.isDisabled ? "not-allowed" : "pointer",
    display: "flex",
    height: "100%",
    justifyContent: "center",
    padding: "0 8px",
    "&:hover": {
      color: "var(--react-select-text)",
    },
  }),
  dropdownIndicator: (base, state) => ({
    ...base,
    alignItems: "center",
    alignSelf: "center",
    color: state.isFocused ? "var(--react-select-text)" : "var(--react-select-muted)",
    cursor: state.isDisabled ? "not-allowed" : "pointer",
    display: "flex",
    height: "100%",
    justifyContent: "center",
    padding: "0 8px",
    "&:hover": {
      color: "var(--react-select-text)",
    },
  }),
  indicatorSeparator: () => ({ display: "none" }),
  menu: (base) => ({
    ...base,
    marginTop: 4,
    border: "1px solid var(--react-select-border)",
    borderRadius: 4,
    backgroundColor: "var(--react-select-menu-bg)",
    boxShadow: "0 8px 20px var(--react-select-shadow)",
    overflow: "hidden",
  }),
  menuList: (base) => ({
    ...base,
    padding: 4,
  }),
  option: (base, state) => ({
    ...base,
    borderRadius: 2,
    cursor: state.isDisabled ? "not-allowed" : "pointer",
    color: state.isDisabled ? "var(--react-select-disabled-text)" : "var(--react-select-text)",
    fontWeight: state.isSelected ? 600 : 400,
    backgroundColor: state.isSelected
      ? "var(--react-select-option-selected)"
      : state.isFocused
        ? "var(--react-select-option-hover)"
        : "transparent",
    "&:active": {
      backgroundColor: state.isDisabled
        ? "transparent"
        : state.isSelected
          ? "var(--react-select-option-selected)"
          : "var(--react-select-option-active)",
    },
  }),
  multiValue: (base) => ({
    ...base,
    margin: 0,
    flexShrink: 0,
    borderRadius: 4,
    backgroundColor: "var(--react-select-chip-bg)",
    maxHeight: 24,
  }),
  multiValueLabel: (base) => ({
    ...base,
    padding: "4px 6px",
    fontSize: 13,
    lineHeight: 1,
    color: "var(--react-select-chip-text)",
  }),
  multiValueRemove: (base, state) => ({
    ...base,
    padding: "2px 6px",
    lineHeight: 1,
    color: "var(--react-select-chip-text)",
    cursor: "pointer",
    "&:hover": {
      backgroundColor: "var(--react-select-chip-remove-hover)",
      color: "var(--react-select-chip-text)",
    },
    ...(state.isFocused ? { backgroundColor: "var(--react-select-chip-remove-hover)" } : {}),
  }),
  noOptionsMessage: (base) => ({
    ...base,
    color: "var(--react-select-muted)",
  }),
};

export default function SmartSelect<
  Option,
  IsMulti extends boolean = false,
  Group extends GroupBase<Option> = GroupBase<Option>,
>(props: SmartSelectProps<Option, IsMulti, Group>) {
  return (
    <Select
      {...props}
      classNamePrefix="rs"
      styles={reactSelectStyles as StylesConfig<Option, IsMulti, Group>}
    />
  );
}
