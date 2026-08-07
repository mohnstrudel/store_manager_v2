import { Suspense, useCallback, useMemo, useState } from "react";
import DestroyCheckbox from "@/components/DestroyCheckbox";
import FormControl from "@/components/FormControl";
import FormError from "@/components/FormError";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import NestedFormContainer from "@/components/NestedFormContainer";
import FormSmartSelect, { SelectSkeleton } from "@/components/FormSmartSelect";
import SmartSelect from "@/components/lazySmartSelect";
import { toSelectedOption } from "@/utils/selectOptions";
import type { SectionRow } from "@/utils/useDynamicSection";
import { type SelectOption, type VariantFormData } from "../../types";
import { variantFormTitle } from "../variantDrafts";

const SELECT_FALLBACK = <SelectSkeleton />;

type VariantFieldsProps = {
  colors: SelectOption<number>[];
  errors?: Record<string, string>;
  index: number;
  onChange: (clientKey: string, changes: Partial<VariantFormData>) => void;
  onRemove: (clientKey: string) => void;
  sizes: SelectOption<number>[];
  variant: SectionRow<VariantFormData>;
  versions: SelectOption<number>[];
};

export default function VariantFields({
  colors,
  errors = EMPTY_ERRORS,
  index,
  onChange,
  onRemove,
  sizes,
  variant,
  versions,
}: VariantFieldsProps) {
  const variantFields = useVariantFieldState(variant, onChange);

  const prefix = `variants.${index}`;
  const skuError = errors[`${prefix}.sku`];
  const sizeError = errors[`${prefix}.size_id`];
  const versionError = errors[`${prefix}.version_id`];
  const colorError = errors[`${prefix}.color_id`];
  const combinationError = errors[`${prefix}.base`];

  const displayVariant = {
    ...variant,
    color_id: variantFields.colorId,
    size_id: variantFields.sizeId,
    version_id: variantFields.versionId,
  };
  const title = variantFormTitle(displayVariant, colors, sizes, versions);
  const isDimmed = variant.deactivated || variantFields.isMarkedForDeletion;
  const sizeHasError = !!(sizeError || combinationError);
  const handleRemove = useCallback(
    () => onRemove(variant.clientKey),
    [onRemove, variant.clientKey],
  );
  const actions = useMemo(
    () => (
      <VariantActions
        index={index}
        onMarkedForDeletionChange={variantFields.setIsMarkedForDeletion}
        onRemove={handleRemove}
        variant={variant}
      />
    ),
    [handleRemove, index, variant, variantFields.setIsMarkedForDeletion],
  );

  return (
    <NestedFormContainer
      actions={actions}
      className={`variant-fields ${isDimmed ? "opacity-50" : ""}`}
      title={title}
    >
      <input name={`variants[${index}][id]`} type="hidden" defaultValue={variant.id ?? ""} />
      <input name={`variants[${index}][client_key]`} type="hidden" value={variant.clientKey} />

      <FormRow>
        <FormControl
          className={`w-full ${sizeHasError ? "field_with_errors" : ""}`}
          htmlFor={`variant-${index}-size`}
          label="Size"
        >
          <Suspense fallback={SELECT_FALLBACK}>
            <SmartSelect
              isClearable
              inputId={`variant-${index}-size`}
              options={sizes}
              name={`variants[${index}][size_id]`}
              defaultValue={toSelectedOption(sizes, variantFields.sizeId)}
              onChange={variantFields.selectSize}
            />
          </Suspense>
          <FormError inline>{sizeError}</FormError>
          <FormError inline>{combinationError}</FormError>
        </FormControl>

        <FormSmartSelect
          className="w-full"
          error={versionError}
          isClearable
          inputId={`variant-${index}-version`}
          label="Version"
          name={`variants[${index}][version_id]`}
          defaultValue={toSelectedOption(versions, variantFields.versionId)}
          onChange={variantFields.selectVersion}
          options={versions}
        />

        <FormSmartSelect
          className="w-full"
          error={colorError}
          isClearable
          inputId={`variant-${index}-color`}
          label="Color"
          name={`variants[${index}][color_id]`}
          defaultValue={toSelectedOption(colors, variantFields.colorId)}
          onChange={variantFields.selectColor}
          options={colors}
        />
      </FormRow>

      <FormInput
        defaultValue={variant.sku}
        error={skuError}
        label="SKU"
        name={`variants[${index}][sku]`}
        placeholder="SKU"
      />

      <FormRow>
        <FormInput
          className="w-full"
          defaultValue={variant.weight}
          label="Weight (kg)"
          min="0"
          name={`variants[${index}][weight]`}
          step="0.01"
          type="number"
        />
        <FormInput
          className="w-full"
          defaultValue={variant.purchase_cost}
          label="List cost"
          min="0"
          name={`variants[${index}][purchase_cost]`}
          step="0.01"
          type="number"
        />
        <FormInput
          className="w-full"
          defaultValue={variant.selling_price}
          label="Selling Price"
          min="0"
          name={`variants[${index}][selling_price]`}
          step="0.01"
          type="number"
        />
      </FormRow>
    </NestedFormContainer>
  );
}

function VariantActions({
  index,
  onMarkedForDeletionChange,
  onRemove,
  variant,
}: {
  index: number;
  onMarkedForDeletionChange: (checked: boolean) => void;
  onRemove: () => void;
  variant: VariantFormData;
}) {
  if (variant.deactivated) {
    return <span className="text-sm text-gray-500 dark:text-gray-400">(Deactivated)</span>;
  }

  if (!variant.id) {
    return (
      <button className="text-sm btn_rounded btn_red" onClick={onRemove} type="button">
        Cancel
      </button>
    );
  }

  return (
    <DestroyCheckbox
      defaultChecked={variant._destroy}
      name={`variants[${index}][_destroy]`}
      onChange={onMarkedForDeletionChange}
    />
  );
}

function useVariantFieldState(
  variant: SectionRow<VariantFormData>,
  onChange: (clientKey: string, changes: Partial<VariantFormData>) => void,
) {
  const [sizeId, setSizeId] = useState<number | null>(variant.size_id);
  const [versionId, setVersionId] = useState<number | null>(variant.version_id);
  const [colorId, setColorId] = useState<number | null>(variant.color_id);
  const [isMarkedForDeletion, setIsMarkedForDeletion] = useState(variant._destroy);
  const markForDeletion = useCallback(
    (checked: boolean) => {
      setIsMarkedForDeletion(checked);
      onChange(variant.clientKey, { _destroy: checked });
    },
    [onChange, variant.clientKey],
  );

  const selectSize = useCallback(
    (option: SelectOption<number> | null) => {
      const size_id = option?.value ?? null;
      setSizeId(size_id);
      onChange(variant.clientKey, { size_id });
    },
    [onChange, variant.clientKey],
  );
  const selectVersion = useCallback(
    (option: SelectOption<number> | null) => {
      const version_id = option?.value ?? null;
      setVersionId(version_id);
      onChange(variant.clientKey, { version_id });
    },
    [onChange, variant.clientKey],
  );
  const selectColor = useCallback(
    (option: SelectOption<number> | null) => {
      const color_id = option?.value ?? null;
      setColorId(color_id);
      onChange(variant.clientKey, { color_id });
    },
    [onChange, variant.clientKey],
  );

  return {
    colorId,
    isMarkedForDeletion,
    selectColor,
    selectSize,
    selectVersion,
    setIsMarkedForDeletion: markForDeletion,
    sizeId,
    versionId,
  };
}

const EMPTY_ERRORS: Record<string, string> = {};
