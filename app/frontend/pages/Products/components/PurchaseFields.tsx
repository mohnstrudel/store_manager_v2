import FormInput from "@/components/FormInput";
import FormSmartSelect from "@/components/FormSmartSelect";
import { type PurchaseFormData, type SelectOption } from "../types";

type PurchaseFieldsProps = {
  errors?: Record<string, string | undefined>;
  purchase: PurchaseFormData;
  suppliers: SelectOption<number>[];
  warehouses: SelectOption<number>[];
};

function toSelectedOption(
  options: SelectOption<number>[],
  value: number | null,
): SelectOption<number> | null {
  return options.find((option) => option.value === value) ?? null;
}

export default function PurchaseFields({
  errors = {},
  purchase,
  suppliers,
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

  return (
    <div className="purchase-fields border border-gray-200 dark:border-gray-800 rounded-xl p-4 pb-8 max-w-full lg:max-w-4/7">
      <h6 className="font-semibold mb-4">New Purchase</h6>
      {baseError && <p className="text-error mb-4">{baseError}</p>}

      <div className="flex justify-between gap-4 flex-col lg:flex-row">
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
      </div>

      <div className="flex justify-between gap-4 flex-col lg:flex-row mt-4">
        <FormInput
          className="w-full"
          defaultValue={purchase.item_price}
          error={itemPriceError}
          label="Item price"
          name="purchase[item_price]"
        />
        <FormInput
          className="w-full"
          defaultValue={purchase.amount}
          error={amountError}
          label="Amount"
          name="purchase[amount]"
        />
        <FormInput
          className="w-full"
          defaultValue={purchase.payment_value}
          error={paymentValueError}
          label="What did you pay in total?"
          name="purchase[payment_value]"
          step="any"
          type="number"
        />
      </div>

      {warehouses.length > 0 && (
        <FormSmartSelect
          className="mt-4"
          defaultValue={toSelectedOption(warehouses, purchase.warehouse_id)}
          error={warehouseError}
          isClearable
          inputId="purchase-warehouse"
          label="Initial warehouse"
          name="purchase[warehouse_id]"
          options={warehouses}
        />
      )}
    </div>
  );
}
