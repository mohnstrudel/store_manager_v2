import { useState } from "react";
import { usePage } from "@inertiajs/react";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSmartSelect from "@/components/FormSmartSelect";
import ImageUploader from "@/components/ImageUploader";
import ResourceForm from "@/components/ResourceForm";
import { toSelectedOption } from "@/lib/selectOptions";
import type { PurchaseItemFormOptions, PurchaseItemFormRecord, SelectOption } from "../types";

type FormProps = {
  action: string;
  cancelHref: string;
  method: "post" | "patch";
  options: PurchaseItemFormOptions;
  purchase_item: PurchaseItemFormRecord;
  submitLabel: string;
};

type PageErrors = Record<string, string | undefined>;

export default function Form({
  action,
  cancelHref,
  method,
  options,
  purchase_item,
  submitLabel,
}: FormProps) {
  const { errors = {} } = usePage().props as { errors?: PageErrors };
  const [media, setMedia] = useState(() => purchase_item.media);

  return (
    <ResourceForm action={action} cancelHref={cancelHref} method={method} submitLabel={submitLabel}>
      <PurchaseItemLinkingFields errors={errors} options={options} purchase_item={purchase_item} />
      <PurchaseItemDimensionFields errors={errors} purchase_item={purchase_item} />
      <PurchaseItemShippingFields errors={errors} options={options} purchase_item={purchase_item} />
      <ImageUploader
        fieldNamePrefix="purchase_item[media]"
        imageFieldName="image"
        media={media}
        onMediaChange={setMedia}
      />
      {purchase_item.redirect_to_sale_item && (
        <input name="purchase_item[redirect_to_sale_item]" type="hidden" value="1" />
      )}
    </ResourceForm>
  );
}

function PurchaseItemLinkingFields({
  errors,
  options,
  purchase_item,
}: {
  errors: PageErrors;
  options: PurchaseItemFormOptions;
  purchase_item: PurchaseItemFormRecord;
}) {
  return (
    <FormRow>
      <FormSmartSelect<SelectOption>
        defaultValue={toSelectedOption(options.warehouses, purchase_item.warehouse_id)}
        error={errors.warehouse ?? errors.warehouse_id}
        inputId="purchase_item_warehouse_id"
        isClearable
        label="Warehouse"
        name="purchase_item[warehouse_id]"
        options={options.warehouses}
      />
      <FormSmartSelect<SelectOption>
        defaultValue={toSelectedOption(options.purchases, purchase_item.purchase_id)}
        error={errors.purchase ?? errors.purchase_id}
        inputId="purchase_item_purchase_id"
        isClearable
        label="Purchase"
        name="purchase_item[purchase_id]"
        options={options.purchases}
      />
      <FormSmartSelect<SelectOption>
        defaultValue={toSelectedOption(options.sale_items, purchase_item.sale_item_id)}
        error={errors.sale_item ?? errors.sale_item_id}
        inputId="purchase_item_sale_item_id"
        isClearable
        label="Sale Item"
        name="purchase_item[sale_item_id]"
        options={options.sale_items}
      />
    </FormRow>
  );
}

function PurchaseItemDimensionFields({
  errors,
  purchase_item,
}: {
  errors: PageErrors;
  purchase_item: PurchaseItemFormRecord;
}) {
  return (
    <FormRow>
      <FormInput
        defaultValue={purchase_item.length}
        error={errors.length}
        label="Length, cm"
        name="purchase_item[length]"
      />
      <FormInput
        defaultValue={purchase_item.width}
        error={errors.width}
        label="Width, cm"
        name="purchase_item[width]"
      />
      <FormInput
        defaultValue={purchase_item.height}
        error={errors.height}
        label="Height, cm"
        name="purchase_item[height]"
      />
      <FormInput
        defaultValue={purchase_item.weight}
        error={errors.weight}
        label="Weight, kg"
        name="purchase_item[weight]"
      />
    </FormRow>
  );
}

function PurchaseItemShippingFields({
  errors,
  options,
  purchase_item,
}: {
  errors: PageErrors;
  options: PurchaseItemFormOptions;
  purchase_item: PurchaseItemFormRecord;
}) {
  return (
    <FormRow>
      <FormInput
        defaultValue={purchase_item.expenses}
        error={errors.expenses}
        label="Expenses"
        name="purchase_item[expenses]"
      />
      <FormInput
        defaultValue={purchase_item.shipping_cost}
        error={errors.shipping_cost}
        label="Shipping"
        name="purchase_item[shipping_cost]"
      />
      <FormInput
        defaultValue={purchase_item.tracking_number}
        error={errors.tracking_number}
        label="Tracking Number"
        name="purchase_item[tracking_number]"
      />
      <FormSmartSelect<SelectOption>
        defaultValue={toSelectedOption(
          options.shipping_companies,
          purchase_item.shipping_company_id,
        )}
        error={errors.shipping_company ?? errors.shipping_company_id}
        inputId="purchase_item_shipping_company_id"
        isClearable
        label="Shipping Company"
        name="purchase_item[shipping_company_id]"
        options={options.shipping_companies}
      />
    </FormRow>
  );
}
