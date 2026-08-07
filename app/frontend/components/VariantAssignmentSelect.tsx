import { useCallback, useEffect, useRef, useState } from "react";
import FormControl from "@/components/FormControl";
import FormSmartSelect, { SelectSkeleton } from "@/components/FormSmartSelect";
import routes from "@/utils/routes";
import type { VariantAssignmentOption, VariantAvailability } from "@/types/variantAssignment";

type VariantAssignmentSelectProps = {
  error?: string;
  initialAvailability: VariantAvailability | null;
  initialProductId: number | null;
  inputId: string;
  name: string;
  onChange: (variantId: number | null) => void;
  productId: number | null;
  value: number | null;
};

type AvailabilityState = {
  availability: VariantAvailability | null;
  status: "empty" | "error" | "loading" | "ready";
};

export default function VariantAssignmentSelect({
  error,
  initialAvailability,
  initialProductId,
  inputId,
  name,
  onChange,
  productId,
  value,
}: VariantAssignmentSelectProps) {
  const availability = useVariantAvailability(productId, initialProductId, initialAvailability);
  const baseVariant = availability.availability?.variants.find((variant) => variant.base_model);
  const handleSelectionChange = useCallback(
    (option: VariantAssignmentOption | null) => onChange(option?.value ?? null),
    [onChange],
  );

  useEffect(() => {
    if (availability.availability?.mode !== "base" || !baseVariant) return;
    if (value === baseVariant.value) return;

    onChange(baseVariant.value);
  }, [availability.availability?.mode, baseVariant, onChange, value]);

  if (availability.status === "loading") {
    return (
      <FormControl error={error} htmlFor={inputId} label="Variant">
        <input name={name} type="hidden" value="" />
        <SelectSkeleton />
      </FormControl>
    );
  }

  if (availability.status === "error") {
    return (
      <VariantAvailabilityMessage
        error={error}
        inputId={inputId}
        message="Could not load Variants. Choose the Product again to retry."
        name={name}
      />
    );
  }

  if (availability.availability?.mode === "base" && baseVariant) {
    return (
      <FormControl error={error} htmlFor={inputId} label="Variant">
        <input id={inputId} name={name} type="hidden" value={baseVariant.value} />
        <p>Base Model</p>
      </FormControl>
    );
  }

  if (availability.availability?.mode === "select") {
    if (availability.availability.variants.length === 0) {
      return (
        <VariantAvailabilityMessage
          error={error}
          inputId={inputId}
          message="No assignable Variants are available."
          name={name}
        />
      );
    }

    return (
      <FormSmartSelect
        error={error}
        inputId={inputId}
        isClearable
        label="Variant"
        name={name}
        onChange={handleSelectionChange}
        options={availability.availability.variants}
        value={selectedVariant(availability.availability.variants, value)}
      />
    );
  }

  return (
    <VariantAvailabilityMessage
      error={error}
      inputId={inputId}
      message="Select a Product first."
      name={name}
    />
  );
}

function VariantAvailabilityMessage({
  error,
  inputId,
  message,
  name,
}: {
  error?: string;
  inputId: string;
  message: string;
  name: string;
}) {
  return (
    <FormControl error={error} htmlFor={inputId} label="Variant">
      <input id={inputId} name={name} type="hidden" value="" />
      <p>{message}</p>
    </FormControl>
  );
}

function useVariantAvailability(
  productId: number | null,
  initialProductId: number | null,
  initialAvailability: VariantAvailability | null,
): AvailabilityState {
  const loadedProductId = useRef(initialAvailability ? initialProductId : null);
  const [state, setState] = useState<AvailabilityState>(() => ({
    availability: initialAvailability,
    status: initialAvailability ? "ready" : "empty",
  }));

  useEffect(() => {
    if (productId == null) {
      loadedProductId.current = null;
      setState({ availability: null, status: "empty" });
      return undefined;
    }

    if (loadedProductId.current === productId) return undefined;

    setState({ availability: null, status: "loading" });
    const controller = new AbortController();
    let active = true;

    loadAvailability(productId, controller.signal)
      .then((availability) => {
        if (!active) return;

        loadedProductId.current = productId;
        setState({ availability, status: "ready" });
      })
      .catch((loadError: unknown) => {
        if (!active || isAbortError(loadError)) return;

        loadedProductId.current = productId;
        setState({ availability: null, status: "error" });
      });

    return () => {
      active = false;
      controller.abort();
    };
  }, [productId]);

  return state;
}

function selectedVariant(options: VariantAssignmentOption[], value: number | null) {
  return options.find((option) => option.value === value) ?? null;
}

async function loadAvailability(productId: number, signal: AbortSignal) {
  const path = routes.productsAssignableVariants.show.path({ product_id: productId });
  const response = await fetch(path, {
    headers: { Accept: "application/json" },
    signal,
  });
  if (!response.ok) throw new Error(`Request failed with status ${response.status}`);

  return (await response.json()) as VariantAvailability;
}

function isAbortError(error: unknown) {
  return error instanceof Error && error.name === "AbortError";
}
