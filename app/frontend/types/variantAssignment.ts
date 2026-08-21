export type VariantAssignmentOption = {
  value: number;
  label: string;
  base_model: boolean;
};

export type VariantAvailability = {
  mode: "base" | "select";
  variants: VariantAssignmentOption[];
};
