import { useCallback, useMemo, useState } from "react";
import DestroyCheckbox from "@/components/DestroyCheckbox";
import FormInput from "@/components/FormInput";
import NestedFormContainer from "@/components/NestedFormContainer";
import FormSmartSelect from "@/components/FormSmartSelect";
import VariantAssignmentSelect from "@/components/VariantAssignmentSelect";
import { toSelectedOption } from "@/utils/selectOptions";
import type { SaleItemFormRecord, SelectOption } from "../../types";

type SaleItemFieldsProps = {
  errors?: Record<string, string>;
  index: number;
  onRemove: (clientKey: string) => void;
  productOptions: SelectOption<number>[];
  saleItem: SaleItemFormRecord & { clientKey: string };
};

export default function SaleItemFields({
  errors = EMPTY_ERRORS,
  index,
  onRemove,
  productOptions,
  saleItem,
}: SaleItemFieldsProps) {
  const saleItemFields = useSaleItemFieldState(saleItem, productOptions);
  const prefix = `sale_items[${index}]`;
  const errorPrefix = `sale_items.${index}`;
  const handleRemove = useCallback(
    () => onRemove(saleItem.clientKey),
    [onRemove, saleItem.clientKey],
  );

  const actions = useMemo(
    () =>
      saleItem.id ? (
        <DestroyCheckbox defaultChecked={saleItem._destroy} name={`${prefix}[_destroy]`} />
      ) : (
        <button className="btn_rounded btn_red text-sm" onClick={handleRemove} type="button">
          Cancel
        </button>
      ),
    [handleRemove, prefix, saleItem._destroy, saleItem.id],
  );

  return (
    <NestedFormContainer
      actions={actions}
      className="sales_form__product_fields"
      title={saleItemFields.productLabel}
    >
      {saleItem.id && <input defaultValue={saleItem.id} name={`${prefix}[id]`} type="hidden" />}
      {!saleItem.id && <input defaultValue="0" name={`${prefix}[_destroy]`} type="hidden" />}

      <FormSmartSelect
        defaultValue={toSelectedOption(productOptions, saleItemFields.productId)}
        error={errors[`${errorPrefix}.product`] || errors[`${errorPrefix}.product_id`]}
        inputId={`sale_item_${index}_product_id`}
        isClearable
        label="Product"
        name={`${prefix}[product_id]`}
        onChange={saleItemFields.selectProduct}
        options={productOptions}
      />

      <VariantAssignmentSelect
        error={errors[`${errorPrefix}.variant`] || errors[`${errorPrefix}.variant_id`]}
        initialAvailability={saleItem.variant_availability}
        initialProductId={saleItem.product_id}
        inputId={`sale_item_${index}_variant_id`}
        name={`${prefix}[variant_id]`}
        onChange={saleItemFields.selectVariant}
        productId={saleItemFields.productId}
        value={saleItemFields.variantId}
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

function useSaleItemFieldState(
  saleItem: SaleItemFormRecord & { clientKey: string },
  productOptions: SelectOption<number>[],
) {
  const [productId, setProductId] = useState<number | null>(saleItem.product_id);
  const [variantId, setVariantId] = useState<number | null>(saleItem.variant_id);
  const productLabel =
    productOptions.find((option) => option.value === productId)?.label ?? "New product";
  const selectProduct = useCallback((option: SelectOption<number> | null) => {
    setProductId(option?.value ?? null);
    setVariantId(null);
  }, []);
  const selectVariant = useCallback((selectedVariantId: number | null) => {
    setVariantId(selectedVariantId);
  }, []);

  return { productId, productLabel, selectProduct, selectVariant, variantId };
}

const EMPTY_ERRORS: Record<string, string> = {};
