import { useState } from "react";
import FormInput from "@/components/FormInput";
import FormSmartSelect from "@/components/FormSmartSelect";
import SmartSelect from "@/components/SmartSelect";
import { type SelectOption, type VariantFormData } from "../types";

type VariantFieldsProps = {
  colors: SelectOption<number>[];
  errors?: Record<string, string | undefined>;
  index: number;
  onRemove: (index: number) => void;
  sizes: SelectOption<number>[];
  variant: VariantFormData;
  versions: SelectOption<number>[];
};

function toSelectedOption(
  options: SelectOption<number>[],
  value: number | null,
): SelectOption<number> | null {
  return options.find((option) => option.value === value) ?? null;
}

function generateVariantTitle(
  variant: VariantFormData,
  colors: SelectOption<number>[],
  sizes: SelectOption<number>[],
  versions: SelectOption<number>[],
): string {
  const parts: string[] = [];

  if (variant.size_id) {
    const size = sizes.find((s) => s.value === variant.size_id);
    if (size) parts.push(size.label);
  }

  if (variant.version_id) {
    const version = versions.find((v) => v.value === variant.version_id);
    if (version) parts.push(version.label);
  }

  if (variant.color_id) {
    const color = colors.find((c) => c.value === variant.color_id);
    if (color) parts.push(color.label);
  }

  return parts.length > 0 ? parts.join(" | ") : "Base Model";
}

function VariantActions({
  index,
  onRemove,
  variant,
}: {
  index: number;
  onRemove: (index: number) => void;
  variant: VariantFormData;
}) {
  if (variant.deactivated) {
    return <span className="text-sm text-gray-500 dark:text-gray-400">(Deactivated)</span>;
  }

  if (!variant.id) {
    return (
      <button className="btn-rounded btn-red m-0" onClick={() => onRemove(index)} type="button">
        Remove
      </button>
    );
  }

  return (
    <>
      <input name={`variants[${index}][_destroy]`} type="hidden" defaultValue="0" />
      <label className="m-0 flex items-center gap-2 text-sm cursor-pointer text-red-600 dark:text-red-900">
        <input
          className="m-0 w-4 h-4 text-red-600 rounded focus:ring-red-500"
          defaultChecked={variant._destroy}
          name={`variants[${index}][_destroy]`}
          type="checkbox"
          value="1"
        />
        <span>{variant.has_sales_or_purchases ? "Deactivate?" : "Destroy?"}</span>
      </label>
    </>
  );
}

export default function VariantFields({
  colors,
  errors = {},
  index,
  onRemove,
  sizes,
  variant,
  versions,
}: VariantFieldsProps) {
  const [sizeId, setSizeId] = useState<number | null>(variant.size_id);
  const [versionId, setVersionId] = useState<number | null>(variant.version_id);
  const [colorId, setColorId] = useState<number | null>(variant.color_id);

  const prefix = `variants.${index}`;
  const skuError = errors[`${prefix}.sku`];
  const sizeError = errors[`${prefix}.size_id`];
  const versionError = errors[`${prefix}.version_id`];
  const colorError = errors[`${prefix}.color_id`];
  const combinationError = errors[`${prefix}.base`];

  const displayVariant = { ...variant, size_id: sizeId, version_id: versionId, color_id: colorId };
  const title = generateVariantTitle(displayVariant, colors, sizes, versions);

  return (
    <div
      className={`variant-fields border border-gray-200 dark:border-gray-800 rounded-xl p-4 pb-8 ${variant.deactivated ? "opacity-50" : ""}`}
    >
      <div className="flex justify-between items-start flex-col lg:flex-row lg:items-center gap-2">
        <h6 className="font-semibold">{title}</h6>
        <VariantActions index={index} onRemove={onRemove} variant={variant} />
      </div>

      <input name={`variants[${index}][id]`} type="hidden" defaultValue={variant.id ?? ""} />

      <div className="flex justify-between gap-4 flex-col lg:flex-row mt-4">
        <div className="w-full">
          <label htmlFor={`variant-${index}-size`}>Size</label>
          <SmartSelect
            isClearable
            inputId={`variant-${index}-size`}
            options={sizes}
            name={`variants[${index}][size_id]`}
            defaultValue={toSelectedOption(sizes, sizeId)}
            onChange={(option) => setSizeId(option?.value ?? null)}
          />
          {sizeError && <p className="text-error mt-2">{sizeError}</p>}
          {combinationError && <p className="text-error mt-2">{combinationError}</p>}
        </div>
        <FormSmartSelect
          className="w-full"
          error={versionError}
          isClearable
          inputId={`variant-${index}-version`}
          label="Version"
          name={`variants[${index}][version_id]`}
          defaultValue={toSelectedOption(versions, versionId)}
          onChange={(option) => setVersionId(option?.value ?? null)}
          options={versions}
        />
        <FormSmartSelect
          className="w-full"
          error={colorError}
          isClearable
          inputId={`variant-${index}-color`}
          label="Color"
          name={`variants[${index}][color_id]`}
          defaultValue={toSelectedOption(colors, colorId)}
          onChange={(option) => setColorId(option?.value ?? null)}
          options={colors}
        />
      </div>

      <div className="flex flex-col gap-4 mt-4">
        <FormInput
          defaultValue={variant.sku}
          error={skuError}
          label="SKU"
          name={`variants[${index}][sku]`}
          placeholder="SKU"
        />

        <div className="flex justify-between gap-4 flex-col lg:flex-row">
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
            label="Purchase Cost"
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
        </div>
      </div>
    </div>
  );
}
