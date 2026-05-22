import SmartSelect from "@/components/SmartSelect";
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
        <div className="block w-full">
          <label className="block">Supplier</label>
          <SmartSelect
            isClearable
            inputId="purchase-supplier"
            options={suppliers}
            name="purchase[supplier_id]"
            defaultValue={toSelectedOption(suppliers, purchase.supplier_id)}
          />
          {supplierError && <p className="text-error mt-2">{supplierError}</p>}
        </div>
        <div className="block w-full">
          <label className="block">Order reference</label>
          <input
            defaultValue={purchase.order_reference}
            name="purchase[order_reference]"
            type="text"
          />
          {orderReferenceError && <p className="text-error mt-2">{orderReferenceError}</p>}
        </div>
      </div>

      <div className="flex justify-between gap-4 flex-col lg:flex-row mt-4">
        <div className="block w-full">
          <label className="block">Item price</label>
          <input
            aria-invalid={!!itemPriceError}
            defaultValue={purchase.item_price}
            name="purchase[item_price]"
            type="text"
          />
          {itemPriceError && <p className="text-error mt-2">{itemPriceError}</p>}
        </div>
        <div className="block w-full">
          <label className="block">Amount</label>
          <input
            aria-invalid={!!amountError}
            defaultValue={purchase.amount}
            name="purchase[amount]"
            type="text"
          />
          {amountError && <p className="text-error mt-2">{amountError}</p>}
        </div>
        <div className="block w-full">
          <label className="block">What did you pay in total?</label>
          <input
            defaultValue={purchase.payment_value}
            name="purchase[payment_value]"
            step="any"
            type="number"
          />
          {paymentValueError && <p className="text-error mt-2">{paymentValueError}</p>}
        </div>
      </div>

      {warehouses.length > 0 && (
        <div className="mt-4">
          <label className="block">Initial warehouse</label>
          <SmartSelect
            isClearable
            inputId="purchase-warehouse"
            options={warehouses}
            name="purchase[warehouse_id]"
            defaultValue={toSelectedOption(warehouses, purchase.warehouse_id)}
          />
          {warehouseError && <p className="text-error mt-2">{warehouseError}</p>}
        </div>
      )}
    </div>
  );
}
