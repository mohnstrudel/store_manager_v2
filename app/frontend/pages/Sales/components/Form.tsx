import { useCallback, useState } from "react";
import { useDynamicSection } from "@/utils/useDynamicSection";
import { validateSaleForm } from "./saleFormSchema";
import { toSelectedOption } from "@/utils/selectOptions";
import DynamicNestedForm from "@/components/DynamicNestedForm";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSmartSelect from "@/components/FormSmartSelect";
import ResourceForm from "@/components/ResourceForm";
import AddressFields from "./Form/AddressFields";
import SaleItemFields from "./Form/SaleItemFields";
import type { SaleFormOptions, SaleFormRecord, SaleItemFormRecord } from "../types";

type SaleFormProps = {
  isNew: boolean;
  options: SaleFormOptions;
  sale: SaleFormRecord;
  submitLabel: string;
};

type SaleFormState = ReturnType<typeof useSaleFormState>;

function titleize(str: string): string {
  return str.replace(/[-_]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function newSaleItem(): SaleItemFormRecord {
  return {
    id: null,
    product_id: null,
    variant_id: null,
    qty: "",
    price: "",
    _destroy: false,
    variant_availability: null,
  };
}

export default function SaleForm({ isNew, options, sale, submitLabel }: SaleFormProps) {
  const form = useSaleFormState(sale);

  const validate = useCallback(
    () => validateSaleForm({ customer_id: form.customerId }),
    [form.customerId],
  );

  return (
    <ResourceForm
      action={isNew ? "/sales" : sale.path}
      cancelHref="/sales"
      method={isNew ? "post" : "patch"}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <>
          <SaleStatusField options={options} sale={sale} />
          <SaleCustomerField errors={errors} form={form} options={options} />
          <SaleNoteField sale={sale} />
          <SaleTotalsFields sale={sale} />
          <SaleAddressSections sale={sale} />
          <SaleItemsSection errors={errors} form={form} options={options} />
        </>
      )}
    </ResourceForm>
  );
}

function SaleStatusField({ options, sale }: { options: SaleFormOptions; sale: SaleFormRecord }) {
  return (
    <section className="form_section_item">
      <label htmlFor="sale[status]" className="font-semibold">
        E-Commerce Order Status
      </label>
      <div className="flex flex-wrap gap-4 mt-4">
        {options.status_names.map((statusName) => (
          <SaleStatusOption currentStatus={sale.status} key={statusName} statusName={statusName} />
        ))}
      </div>
    </section>
  );
}

function SaleStatusOption({
  currentStatus,
  statusName,
}: {
  currentStatus: string;
  statusName: string;
}) {
  const inputId = `sale_status_${statusName}`;

  return (
    <div className="flex items-center mr-2">
      <input
        className="p-0"
        defaultChecked={currentStatus === statusName}
        id={inputId}
        name="sale[status]"
        suppressHydrationWarning
        type="radio"
        value={statusName}
      />
      <label className="m-0 p-0 pl-2 cursor-pointer text-sm" htmlFor={inputId}>
        {titleize(statusName)}
      </label>
    </div>
  );
}

function SaleCustomerField({
  errors,
  form,
  options,
}: {
  errors: Record<string, string>;
  form: SaleFormState;
  options: SaleFormOptions;
}) {
  return (
    <FormSmartSelect
      defaultValue={toSelectedOption(options.customers, form.customerId)}
      error={errors.customer || errors.customer_id}
      inputId="sale_customer_id"
      isClearable
      label="Customer"
      name="sale[customer_id]"
      onChange={form.selectCustomer}
      options={options.customers}
    />
  );
}

function SaleNoteField({ sale }: { sale: SaleFormRecord }) {
  return <FormInput defaultValue={sale.note} label="Note" name="sale[note]" />;
}

function SaleTotalsFields({ sale }: { sale: SaleFormRecord }) {
  return (
    <FormRow>
      <FormInput
        defaultValue={sale.total}
        label="Total price"
        name="sale[total]"
        step="any"
        type="number"
      />
      <FormInput
        defaultValue={sale.discount_total}
        label="Discount total"
        name="sale[discount_total]"
        step="any"
        type="number"
      />
      <FormInput
        defaultValue={sale.shipping_total}
        label="Shipping total"
        name="sale[shipping_total]"
        step="any"
        type="number"
      />
    </FormRow>
  );
}

function SaleAddressSections({ sale }: { sale: SaleFormRecord }) {
  return (
    <fieldset className="mt-2 grid grid-cols-1 gap-6 lg:grid-cols-2">
      <AddressFields
        address={sale.shipping_address}
        namePrefix="sale[shipping_address]"
        title="Shipping Address"
      />
      <AddressFields
        address={sale.billing_address}
        namePrefix="sale[billing_address]"
        title="Billing Address"
      />
    </fieldset>
  );
}

function SaleItemsSection({
  errors,
  form,
  options,
}: {
  errors: Record<string, string>;
  form: SaleFormState;
  options: SaleFormOptions;
}) {
  return (
    <DynamicNestedForm name="Product" onAdd={form.saleItems.add}>
      {form.saleItems.items.map((saleItem, index) => (
        <SaleItemFields
          errors={errors}
          index={index}
          key={saleItem.clientKey}
          onRemove={form.saleItems.remove}
          productOptions={options.products}
          saleItem={saleItem}
        />
      ))}
    </DynamicNestedForm>
  );
}

function useSaleFormState(sale: SaleFormRecord) {
  const [customerId, setCustomerId] = useState<number | null>(sale.customer_id);
  const saleItems = useDynamicSection(sale.sale_items, newSaleItem, {
    keyForInitial: saleItemKey,
  });

  function selectCustomer(option: SaleFormOptions["customers"][number] | null) {
    setCustomerId(option?.value ?? null);
  }

  return { customerId, saleItems, selectCustomer };
}

function saleItemKey(saleItem: SaleItemFormRecord, index: number) {
  return saleItem.id ? `sale-item-${saleItem.id}` : `initial-sale-item-${index}`;
}
