import { useState } from "react";
import { usePage } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import SmartSelect from "@/components/SmartSelect";
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
      <fieldset className="flex justify-between gap-4 flex-col lg:flex-row">
        <div className="block w-full">
          <label htmlFor="purchase_product_id">Product</label>
          <SmartSelect
            isClearable
            inputId="purchase_product_id"
            name="purchase[product_id]"
            onChange={(option) => {
              setProductId(option?.value ?? null);
              setVariantId(null);
            }}
            options={options.products}
            value={toSelectedOption(options.products, productId)}
          />
        </div>
        <div className="block w-full">
          <label htmlFor="purchase_supplier_id">Supplier</label>
          <SmartSelect
            isClearable
            inputId="purchase_supplier_id"
            name="purchase[supplier_id]"
            onChange={(option) => setSupplierId(option?.value ?? null)}
            options={options.suppliers}
            value={toSelectedOption(options.suppliers, supplierId)}
          />
          {errors.supplier_id && <p className="text-error mt-2">{errors.supplier_id}</p>}
        </div>
      </fieldset>

      <div className="mt-4">
        <ProductVariantSelect
          initialVariants={purchase.variant_options}
          onChange={setVariantId}
          productId={productId}
          productVariantsPath={options.product_variants_path}
          value={variantId}
        />
      </div>

      <fieldset className="flex justify-between gap-4 flex-col lg:flex-row mt-4">
        <div className="block w-full">
          <FormField
            defaultValue={purchase.order_reference}
            error={errors.order_reference}
            label="Order reference"
            name="purchase[order_reference]"
          />
        </div>
      </fieldset>

      <fieldset className="flex justify-between gap-4 flex-col lg:flex-row mt-4">
        <div className="block w-full">
          <FormField
            defaultValue={purchase.item_price}
            error={errors.item_price}
            label="Item price"
            name="purchase[item_price]"
            step="any"
            type="number"
          />
        </div>
        <div className="block w-full">
          <FormField
            defaultValue={purchase.amount}
            error={errors.amount}
            label="Amount"
            name="purchase[amount]"
            type="number"
          />
        </div>
        {isNew && (
          <div className="block w-full">
            <FormField
              defaultValue={purchase.payment_value}
              label="What did you pay in total?"
              name="initial_payment[value]"
              step="any"
              type="number"
            />
          </div>
        )}
      </fieldset>

      {options.warehouses.length > 0 && (
        <div className="mt-4">
          <label htmlFor="purchase_warehouse_id">Initial warehouse</label>
          <SmartSelect
            isClearable
            inputId="purchase_warehouse_id"
            name="purchase[warehouse_id]"
            onChange={(option) => setWarehouseId(option?.value ?? null)}
            options={options.warehouses}
            value={toSelectedOption(options.warehouses, warehouseId)}
          />
        </div>
      )}
    </ResourceForm>
  );
}
