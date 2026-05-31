import { useCallback, useMemo, useState } from "react";
import DestroyCheckbox from "@/components/DestroyCheckbox";
import FormInput from "@/components/FormInput";
import NestedFormContainer from "@/components/NestedFormContainer";
import FormSmartSelect from "@/components/FormSmartSelect";
import { toSelectedOption } from "@/lib/selectOptions";
import type { SaleItemFormRecord, SelectOption } from "../types";

type SaleItemFieldsProps = {
  index: number;
  onRemove: (clientKey: string) => void;
  productOptions: SelectOption<number>[];
  saleItem: SaleItemFormRecord & { clientKey: string };
};

export default function SaleItemFields({
  index,
  onRemove,
  productOptions,
  saleItem,
}: SaleItemFieldsProps) {
  const [productId, setProductId] = useState<number | null>(saleItem.product_id);
  const prefix = `sale_items[${index}]`;
  const productLabel = productOptions.find((o) => o.value === productId)?.label ?? "New product";
  const handleRemove = useCallback(
    () => onRemove(saleItem.clientKey),
    [onRemove, saleItem.clientKey],
  );
  const handleProductChange = useCallback(
    (option: SelectOption<number> | null) => setProductId(option?.value ?? null),
    [],
  );

  const actions = useMemo(
    () =>
      saleItem.id ? (
        <DestroyCheckbox defaultChecked={saleItem._destroy} name={`${prefix}[_destroy]`} />
      ) : (
        <button className="btn_rounded btn_red" onClick={handleRemove} type="button">
          Cancel
        </button>
      ),
    [handleRemove, prefix, saleItem._destroy, saleItem.id],
  );

  return (
    <NestedFormContainer
      actions={actions}
      className="sales_form__product_fields"
      title={productLabel}
    >
      {saleItem.id && <input defaultValue={saleItem.id} name={`${prefix}[id]`} type="hidden" />}
      {!saleItem.id && <input defaultValue="0" name={`${prefix}[_destroy]`} type="hidden" />}

      <FormSmartSelect
        defaultValue={toSelectedOption(productOptions, productId)}
        inputId={`sale_item_${index}_product_id`}
        isClearable
        label="Product"
        name={`${prefix}[product_id]`}
        onChange={handleProductChange}
        options={productOptions}
      />

      <FormInput
        defaultValue={saleItem.qty}
        label="Amount"
        name={`${prefix}[qty]`}
        placeholder="Amount"
        type="number"
      />

      <FormInput
        defaultValue={saleItem.price}
        label="Price"
        name={`${prefix}[price]`}
        placeholder="Price"
        step="any"
        type="number"
      />
    </NestedFormContainer>
  );
}
