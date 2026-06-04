import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type Dispatch,
  type MutableRefObject,
  type SetStateAction,
} from "react";
import SmartSelect from "@/components/SmartSelect";
import { type SelectOption } from "../../types";

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

type ProductVariantSelection = {
  selectVariant: (option: SelectOption<number> | null) => void;
  selectedVariant: SelectOption<number> | null;
  variantOptions: SelectOption<number>[];
};

type LoadedProductVariants = {
  loadedProductId: number | null;
  variantOptions: SelectOption<number>[];
};

export default function ProductVariantSelect({
  initialVariants,
  onChange,
  productId,
  productVariantsPath,
  value,
}: ProductVariantSelectProps) {
  const { selectVariant, selectedVariant, variantOptions } = useProductVariantSelect(
    productId,
    initialVariants,
    productVariantsPath,
    onChange,
    value,
  );

  return (
    <div>
      <label htmlFor="purchase_variant_id">Variant</label>
      <SmartSelect
        inputId="purchase_variant_id"
        name="purchase[variant_id]"
        onChange={selectVariant}
        options={variantOptions}
        value={selectedVariant}
      />
    </div>
  );
}

function useProductVariantSelect(
  productId: number | null,
  initialVariants: SelectOption<number>[],
  path: string,
  onChange: (variantId: number | null) => void,
  value: number | null,
): ProductVariantSelection {
  const { loadedProductId, variantOptions } = useLoadedProductVariants(
    productId,
    initialVariants,
    path,
  );
  const selectedVariant = useSelectedVariant(variantOptions, value);
  const selectVariant = useCallback(
    (option: SelectOption<number> | null) => onChange(option?.value ?? null),
    [onChange],
  );

  useSelectFirstVariantWhenReady({
    loadedProductId,
    onChange,
    productId,
    value,
    variantOptions,
  });

  return { selectVariant, selectedVariant, variantOptions };
}

function useLoadedProductVariants(
  productId: number | null,
  initialVariants: SelectOption<number>[],
  path: string,
): LoadedProductVariants {
  const [variants, setVariants] = useState<SelectOption<number>[]>(initialVariants);
  const [loadedProductId, setLoadedProductId] = useState<number | null>(productId);
  const loadedProductIdRef = useRef(productId);

  useEffect(() => {
    if (!hasSelectedProduct(productId)) {
      clearLoadedVariants(loadedProductIdRef, setVariants, setLoadedProductId);
      return undefined;
    }

    if (shouldResetVariants(loadedProductIdRef.current, productId)) {
      setVariantsAsLoading(setVariants, setLoadedProductId);
    }

    let isActive = true;
    const cancelLoad = loadVariants(path, productId, (loadedVariants) => {
      if (!isActive) return;

      loadedProductIdRef.current = productId;
      setVariants(loadedVariants);
      setLoadedProductId(productId);
    });

    return () => {
      isActive = false;
      cancelLoad();
    };
  }, [productId, path]);

  return { loadedProductId, variantOptions: variants };
}

function useSelectedVariant(variantOptions: SelectOption<number>[], value: number | null) {
  return useMemo(
    () => variantOptions.find((option) => option.value === value) ?? null,
    [value, variantOptions],
  );
}

function useSelectFirstVariantWhenReady({
  loadedProductId,
  onChange,
  productId,
  value,
  variantOptions,
}: {
  loadedProductId: number | null;
  onChange: (variantId: number | null) => void;
  productId: number | null;
  value: number | null;
  variantOptions: SelectOption<number>[];
}) {
  useEffect(() => {
    if (!shouldSelectFirstVariant(productId, loadedProductId, value, variantOptions)) return;

    onChange(variantOptions[0].value);
  }, [loadedProductId, onChange, productId, value, variantOptions]);
}

function hasSelectedProduct(productId: number | null): productId is number {
  return productId != null;
}

function shouldResetVariants(loadedProductId: number | null, productId: number) {
  return loadedProductId !== productId;
}

function setVariantsAsLoading(
  setVariants: Dispatch<SetStateAction<SelectOption<number>[]>>,
  setLoadedProductId: Dispatch<SetStateAction<number | null>>,
) {
  setVariants([]);
  setLoadedProductId(null);
}

function clearLoadedVariants(
  loadedProductIdRef: MutableRefObject<number | null>,
  setVariants: Dispatch<SetStateAction<SelectOption<number>[]>>,
  setLoadedProductId: Dispatch<SetStateAction<number | null>>,
) {
  loadedProductIdRef.current = null;
  setVariants([]);
  setLoadedProductId(null);
}

function shouldSelectFirstVariant(
  productId: number | null,
  loadedProductId: number | null,
  value: number | null,
  variantOptions: SelectOption<number>[],
) {
  return (
    productId != null &&
    loadedProductId === productId &&
    value === null &&
    variantOptions.length > 0
  );
}

function loadVariants(
  path: string,
  productId: number,
  onLoad: (variants: SelectOption<number>[]) => void,
) {
  const controller = new AbortController();

  const url = `${path}?${new URLSearchParams({ product_id: String(productId) })}`;

  fetch(url, {
    headers: { Accept: "application/json" },
    signal: controller.signal,
  })
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
