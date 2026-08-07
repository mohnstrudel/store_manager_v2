import type { SectionRow } from "@/utils/useDynamicSection";
import type { FormOptions, SelectOption, VariantFormData } from "../types";

export type DraftVariantOption = {
  value: string;
  label: string;
  base_model: boolean;
};

export type DraftVariantAvailability = {
  mode: "base" | "select";
  variants: DraftVariantOption[];
};

export function draftVariantAvailability(
  variants: SectionRow<VariantFormData>[],
  options: Pick<FormOptions, "colors" | "sizes" | "versions">,
): DraftVariantAvailability {
  const activeVariants = variants.filter(isActiveDraft);
  const realVariants = activeVariants.filter(isRealDraft);
  const candidates =
    realVariants.length > 0
      ? realVariants
      : activeVariants.filter((variant) => !isRealDraft(variant) && variant.base_model);

  return {
    mode: realVariants.length > 0 ? "select" : "base",
    variants: candidates.map((variant) => ({
      value: variant.clientKey,
      label: variantFormTitle(variant, options.colors, options.sizes, options.versions),
      base_model: !isRealDraft(variant),
    })),
  };
}

export function visibleDraftVariants(
  variants: SectionRow<VariantFormData>[],
): SectionRow<VariantFormData>[] {
  if (!variants.some((variant) => isActiveDraft(variant) && isRealDraft(variant))) {
    return variants;
  }

  return variants.filter((variant) => !(variant.base_model && !isRealDraft(variant)));
}

export function variantFormTitle(
  variant: VariantFormData,
  colors: SelectOption<number>[],
  sizes: SelectOption<number>[],
  versions: SelectOption<number>[],
): string {
  const parts = [
    optionLabel(sizes, variant.size_id),
    optionLabel(versions, variant.version_id),
    optionLabel(colors, variant.color_id),
  ].filter((part): part is string => !!part);

  return parts.length > 0 ? parts.join(" | ") : "Base Model";
}

function isActiveDraft(variant: VariantFormData) {
  return !variant.deactivated && !variant._destroy;
}

function isRealDraft(variant: VariantFormData) {
  return variant.size_id != null || variant.version_id != null || variant.color_id != null;
}

function optionLabel(options: SelectOption<number>[], value: number | null) {
  return options.find((option) => option.value === value)?.label;
}
