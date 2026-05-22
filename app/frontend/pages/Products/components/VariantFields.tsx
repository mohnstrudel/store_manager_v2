import { useState } from "react";
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
      className={[
        "variant-fields border border-gray-200 dark:border-gray-800 rounded-xl p-4 pb-8",
        variant.deactivated ? "opacity-50" : "",
      ]
        .filter(Boolean)
        .join(" ")}
    >
      <div className="flex justify-between items-start flex-col lg:flex-row lg:items-center gap-2">
        <h6 className="font-semibold">{title}</h6>
        {variant.deactivated ? (
          <span className="text-sm text-gray-500 dark:text-gray-400">(Deactivated)</span>
        ) : !variant.id ? (
          <button className="btn-rounded btn-red m-0" onClick={() => onRemove(index)} type="button">
            Remove
          </button>
        ) : (
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
        )}
      </div>

      <input name={`variants[${index}][id]`} type="hidden" defaultValue={variant.id ?? ""} />

      <div className="flex justify-between gap-4 flex-col lg:flex-row">
        <div className="block w-full">
          <label className="mt-4 block">Size</label>
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
        <div className="block w-full">
          <label className="mt-4 block">Version</label>
          <SmartSelect
            isClearable
            inputId={`variant-${index}-version`}
            options={versions}
            name={`variants[${index}][version_id]`}
            defaultValue={toSelectedOption(versions, versionId)}
            onChange={(option) => setVersionId(option?.value ?? null)}
          />
          {versionError && <p className="text-error mt-2">{versionError}</p>}
        </div>
        <div className="block w-full">
          <label className="mt-4 block">Color</label>
          <SmartSelect
            isClearable
            inputId={`variant-${index}-color`}
            options={colors}
            name={`variants[${index}][color_id]`}
            defaultValue={toSelectedOption(colors, colorId)}
            onChange={(option) => setColorId(option?.value ?? null)}
          />
          {colorError && <p className="text-error mt-2">{colorError}</p>}
        </div>
      </div>

      <div className="flex flex-col gap-4 mt-4">
        <div className="block">
          <label className="block">SKU</label>
          <input
            aria-invalid={!!skuError}
            className={["h-fit", skuError ? "border-red-500" : ""].filter(Boolean).join(" ")}
            defaultValue={variant.sku}
            name={`variants[${index}][sku]`}
            placeholder="SKU"
            type="text"
          />
          {skuError && <p className="text-error mt-2">{skuError}</p>}
        </div>

        <div className="flex justify-between gap-4 flex-col lg:flex-row mt-4">
          <div className="block w-full">
            <label className="block">Weight (kg)</label>
            <input
              defaultValue={variant.weight}
              min="0"
              name={`variants[${index}][weight]`}
              step="0.01"
              type="number"
            />
          </div>
          <div className="block w-full">
            <label className="block">Purchase Cost</label>
            <input
              defaultValue={variant.purchase_cost}
              min="0"
              name={`variants[${index}][purchase_cost]`}
              step="0.01"
              type="number"
            />
          </div>
          <div className="block w-full">
            <label className="block">Selling Price</label>
            <input
              defaultValue={variant.selling_price}
              min="0"
              name={`variants[${index}][selling_price]`}
              step="0.01"
              type="number"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
