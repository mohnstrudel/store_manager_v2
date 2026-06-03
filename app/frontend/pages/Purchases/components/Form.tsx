import { useCallback, useState } from "react";
import { usePage } from "@inertiajs/react";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSmartSelect from "@/components/FormSmartSelect";
import ResourceForm from "@/components/ResourceForm";
import { toSelectedOption } from "@/lib/selectOptions";
import ProductVariantSelect from "./Form/ProductVariantSelect";
import { type PurchaseFormOptions, type PurchaseFormRecord } from "../types";

type PurchaseFormProps = {
  isNew: boolean;
  options: PurchaseFormOptions;
  purchase: PurchaseFormRecord;
  submitLabel: string;
};

type PageErrors = Record<string, string | undefined>;

export default function Form({ isNew, options, purchase, submitLabel }: PurchaseFormProps) {
  const { errors = {} } = usePage().props as { errors?: PageErrors };
  const [productId, setProductId] = useState<number | null>(purchase.product_id);
  const [supplierId, setSupplierId] = useState<number | null>(purchase.supplier_id);
  const [variantId, setVariantId] = useState<number | null>(purchase.variant_id);
  const [warehouseId, setWarehouseId] = useState<number | null>(purchase.warehouse_id);

  const selectProduct = useCallback((option: (typeof options.products)[number] | null) => {
    setProductId(option?.value ?? null);
    setVariantId(null);
  }, []);

  const selectSupplier = useCallback((option: (typeof options.suppliers)[number] | null) => {
    setSupplierId(option?.value ?? null);
  }, []);

  const selectWarehouse = useCallback((option: (typeof options.warehouses)[number] | null) => {
    setWarehouseId(option?.value ?? null);
  }, []);

  return (
    <ResourceForm
      action={purchase.path || "/purchases"}
      cancelHref="/purchases"
      method={isNew ? "post" : "patch"}
      submitLabel={submitLabel}
    >
      <FormRow>
        <FormSmartSelect
          isClearable
          inputId="purchase_product_id"
          label="Product"
          name="purchase[product_id]"
          onChange={selectProduct}
          options={options.products}
          value={toSelectedOption(options.products, productId)}
        />
        <FormSmartSelect
          error={errors.supplier_id}
          isClearable
          inputId="purchase_supplier_id"
          label="Supplier"
          name="purchase[supplier_id]"
          onChange={selectSupplier}
          options={options.suppliers}
          value={toSelectedOption(options.suppliers, supplierId)}
        />
      </FormRow>

      <ProductVariantSelect
        initialVariants={purchase.variant_options}
        onChange={setVariantId}
        productId={productId}
        productVariantsPath={options.product_variants_path}
        value={variantId}
      />

      <FormInput
        defaultValue={purchase.order_reference}
        error={errors.order_reference}
        label="Order reference"
        name="purchase[order_reference]"
      />

      <FormRow>
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
      </FormRow>

      {options.warehouses.length > 0 && (
        <FormSmartSelect
          isClearable
          inputId="purchase_warehouse_id"
          label="Initial warehouse"
          name="purchase[warehouse_id]"
          onChange={selectWarehouse}
          options={options.warehouses}
          value={toSelectedOption(options.warehouses, warehouseId)}
        />
      )}
    </ResourceForm>
  );
}
