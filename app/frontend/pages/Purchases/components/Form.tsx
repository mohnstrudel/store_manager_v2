import { useState } from "react";
import { usePage } from "@inertiajs/react";
import FieldSet from "@/components/FieldSet";
import FormInput from "@/components/FormInput";
import FormSmartSelect from "@/components/FormSmartSelect";
import ResourceForm from "@/components/ResourceForm";
import ProductVariantSelect from "./ProductVariantSelect";
import { type PurchaseFormOptions, type PurchaseFormRecord, type SelectOption } from "../types";

type PurchaseFormProps = {
  isNew: boolean;
  options: PurchaseFormOptions;
  purchase: PurchaseFormRecord;
  submitLabel: string;
};

type PageErrors = Record<string, string | undefined>;

function toSelectedOption(
  options: SelectOption<number>[],
  value: number | null,
): SelectOption<number> | null {
  return options.find((option) => option.value === value) ?? null;
}

export default function Form({ isNew, options, purchase, submitLabel }: PurchaseFormProps) {
  const { errors = {} } = usePage().props as { errors?: PageErrors };
  const [productId, setProductId] = useState<number | null>(purchase.product_id);
  const [supplierId, setSupplierId] = useState<number | null>(purchase.supplier_id);
  const [variantId, setVariantId] = useState<number | null>(purchase.variant_id);
  const [warehouseId, setWarehouseId] = useState<number | null>(purchase.warehouse_id);

  return (
    <ResourceForm
      action={purchase.path || "/purchases"}
      cancelHref="/purchases"
      method={isNew ? "post" : "patch"}
      submitLabel={submitLabel}
    >
      <FieldSet>
        <FormSmartSelect
          isClearable
          inputId="purchase_product_id"
          label="Product"
          name="purchase[product_id]"
          onChange={(option) => {
            setProductId(option?.value ?? null);
            setVariantId(null);
          }}
          options={options.products}
          value={toSelectedOption(options.products, productId)}
        />
        <FormSmartSelect
          error={errors.supplier_id}
          isClearable
          inputId="purchase_supplier_id"
          label="Supplier"
          name="purchase[supplier_id]"
          onChange={(option) => setSupplierId(option?.value ?? null)}
          options={options.suppliers}
          value={toSelectedOption(options.suppliers, supplierId)}
        />
      </FieldSet>

      <div className="mt-4">
        <ProductVariantSelect
          initialVariants={purchase.variant_options}
          onChange={setVariantId}
          productId={productId}
          productVariantsPath={options.product_variants_path}
          value={variantId}
        />
      </div>

      <FormInput
        className="mt-4"
        defaultValue={purchase.order_reference}
        error={errors.order_reference}
        label="Order reference"
        name="purchase[order_reference]"
      />

      <FieldSet className="mt-4">
        <FormInput
          defaultValue={purchase.item_price}
          error={errors.item_price}
          label="Item price"
          name="purchase[item_price]"
          step="any"
          type="number"
        />
        <FormInput
          defaultValue={purchase.amount}
          error={errors.amount}
          label="Amount"
          name="purchase[amount]"
          type="number"
        />
        {isNew && (
          <FormInput
            defaultValue={purchase.payment_value}
            label="What did you pay in total?"
            name="initial_payment[value]"
            step="any"
            type="number"
          />
        )}
      </FieldSet>

      {options.warehouses.length > 0 && (
        <FormSmartSelect
          className="mt-4"
          isClearable
          inputId="purchase_warehouse_id"
          label="Initial warehouse"
          name="purchase[warehouse_id]"
          onChange={(option) => setWarehouseId(option?.value ?? null)}
          options={options.warehouses}
          value={toSelectedOption(options.warehouses, warehouseId)}
        />
      )}
    </ResourceForm>
  );
}
