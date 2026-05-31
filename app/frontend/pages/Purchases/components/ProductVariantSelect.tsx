import { useCallback, useEffect, useState } from "react";
import SmartSelect from "@/components/SmartSelect";
import { type SelectOption } from "../types";

type ProductVariantSelectProps = {
  initialVariants: SelectOption<number>[];
  onChange: (variantId: number | null) => void;
  productId: number | null;
  productVariantsPath: string;
  value: number | null;
};

type ProductVariantsResponse = {
  variants?: SelectOption<number>[];
};

export default function ProductVariantSelect({
  initialVariants,
  onChange,
  productId,
  productVariantsPath,
  value,
}: ProductVariantSelectProps) {
  const variantOptions = useProductVariants(productId, initialVariants, productVariantsPath);
  const selectedVariant = variantOptions.find((option) => option.value === value) ?? null;
  const handleChange = useCallback(
    (option: SelectOption<number> | null) => onChange(option?.value ?? null),
    [onChange],
  );

  useEffect(() => {
    if (value === null && variantOptions.length > 0) onChange(variantOptions[0].value);
  }, [onChange, value, variantOptions]);

  return (
    <div>
      <label htmlFor="purchase_variant_id">Variant</label>
      <SmartSelect
        inputId="purchase_variant_id"
        name="purchase[variant_id]"
        onChange={handleChange}
        options={variantOptions}
        value={selectedVariant}
      />
    </div>
  );
}

function useProductVariants(
  productId: number | null,
  initialVariants: SelectOption<number>[],
  path: string,
) {
  const [variants, setVariants] = useState<SelectOption<number>[]>(initialVariants);

  useEffect(() => {
    if (!productId) return undefined;
    return loadVariants(path, productId, setVariants);
  }, [productId, path]);

  return variants;
}

function loadVariants(
  path: string,
  productId: number,
  onLoad: (variants: SelectOption<number>[]) => void,
) {
  const controller = new AbortController();

  const url = `${path}?${new URLSearchParams({ product_id: String(productId) })}`;

  fetch(url, { headers: { Accept: "application/json" }, signal: controller.signal })
    .then(async (response) => {
      if (!response.ok) throw new Error(`Request failed with status ${response.status}`);
      const body: ProductVariantsResponse = await response.json();
      return body;
    })
    .then((body) => onLoad(body.variants ?? []))
    .catch((error: unknown) => {
      if (error instanceof Error && error.name === "AbortError") return;
      console.error("Failed to load purchase variants:", error);
    });

  return () => controller.abort();
}
