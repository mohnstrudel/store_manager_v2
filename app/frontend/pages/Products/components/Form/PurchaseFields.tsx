import { useCallback } from "react";

import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSmartSelect from "@/components/FormSmartSelect";
import NestedFormContainer from "@/components/NestedFormContainer";
import { toSelectedOption } from "@/utils/selectOptions";

import { type PurchaseFormData, type SelectOption } from "../../types";
import type { DraftVariantAvailability, DraftVariantOption } from "../variantDrafts";

type PurchaseFieldsProps = {
  draftAvailability: DraftVariantAvailability;
  errors?: Record<string, string>;
  onVariantChange: (clientKey: string | null) => void;
  purchase: PurchaseFormData;
  suppliers: SelectOption<number>[];
  variantClientKey: string | null;
  warehouses: SelectOption<number>[];
};

const EMPTY_ERRORS: Record<string, string> = {};

export default function PurchaseFields({
  draftAvailability,
  errors = EMPTY_ERRORS,
  onVariantChange,
  purchase,
  suppliers,
  variantClientKey,
  warehouses,
}: PurchaseFieldsProps) {
  const prefix = "purchase.0";
  const baseError = errors[`${prefix}.base`];
  const supplierError = errors[`${prefix}.supplier_id`];
  const orderReferenceError = errors[`${prefix}.order_reference`];
  const itemPriceError = errors[`${prefix}.item_price`];
  const amountError = errors[`${prefix}.amount`];
  const paymentValueError = errors[`${prefix}.payment_value`];
  const warehouseError = errors[`${prefix}.warehouse_id`];
  const variantError = errors[`${prefix}.variant_client_key`] || errors[`${prefix}.variant`];

  return (
    <NestedFormContainer
      className="purchase-fields max-w-full lg:max-w-4/7"
      error={baseError}
      title="New Purchase"
    >
      <FormRow>
        <FormSmartSelect
          className="w-full"
          defaultValue={toSelectedOption(suppliers, purchase.supplier_id)}
          error={supplierError}
          isClearable
          inputId="purchase-supplier"
          label="Supplier"
          name="purchase[supplier_id]"
          options={suppliers}
        />
        <FormInput
          className="w-full"
          defaultValue={purchase.order_reference}
          error={orderReferenceError}
          label="Order reference"
          name="purchase[order_reference]"
        />
      </FormRow>

      <DraftVariantSelect
        availability={draftAvailability}
        error={variantError}
        onChange={onVariantChange}
        value={variantClientKey}
      />

      <FormRow>
        <FormInput
          defaultValue={purchase.item_price}
          error={itemPriceError}
          label="Item price"
          name="purchase[item_price]"
        />
        <FormInput
          defaultValue={purchase.amount}
          error={amountError}
          label="Amount"
          name="purchase[amount]"
        />
        <FormInput
          defaultValue={purchase.payment_value}
          error={paymentValueError}
          label="What did you pay in total?"
          name="purchase[payment_value]"
          step="any"
          type="number"
        />
      </FormRow>

      {warehouses.length > 0 && (
        <FormSmartSelect
          defaultValue={toSelectedOption(warehouses, purchase.warehouse_id)}
          error={warehouseError}
          isClearable
          inputId="purchase-warehouse"
          label="Initial warehouse"
          name="purchase[warehouse_id]"
          options={warehouses}
        />
      )}
    </NestedFormContainer>
  );
}

function DraftVariantSelect({
  availability,
  error,
  onChange,
  value,
}: {
  availability: DraftVariantAvailability;
  error?: string;
  onChange: (clientKey: string | null) => void;
  value: string | null;
}) {
  const handleSelectionChange = useCallback(
    (option: DraftVariantOption | null) => onChange(option?.value ?? null),
    [onChange],
  );

  if (availability.mode === "base") {
    const baseVariant = availability.variants[0];

    return (
      <FormControl error={error} htmlFor="purchase-variant" label="Variant">
        <input
          id="purchase-variant"
          name="purchase[variant_client_key]"
          type="hidden"
          value={baseVariant?.value ?? ""}
        />
        <p>{baseVariant?.label ?? "Base Model"}</p>
      </FormControl>
    );
  }

  return (
    <FormSmartSelect
      error={error}
      inputId="purchase-variant"
      isClearable
      label="Variant"
      name="purchase[variant_client_key]"
      onChange={handleSelectionChange}
      options={availability.variants}
      value={availability.variants.find((variant) => variant.value === value) ?? null}
    />
  );
}
