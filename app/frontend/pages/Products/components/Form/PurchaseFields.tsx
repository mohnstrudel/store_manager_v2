import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import NestedFormContainer from "@/components/NestedFormContainer";
import FormSmartSelect from "@/components/FormSmartSelect";
import { toSelectedOption } from "@/lib/selectOptions";
import { type PurchaseFormData, type SelectOption } from "../../types";

type PurchaseFieldsProps = {
  errors?: Record<string, string>;
  purchase: PurchaseFormData;
  suppliers: SelectOption<number>[];
  warehouses: SelectOption<number>[];
};

const EMPTY_ERRORS: Record<string, string> = {};

export default function PurchaseFields({
  errors = EMPTY_ERRORS,
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
