import { useState } from "react";
import { useDynamicSection } from "@/lib/useDynamicSection";
import { toSelectedOption } from "@/lib/selectOptions";
import DynamicNestedForm from "@/components/DynamicNestedForm";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSmartSelect from "@/components/FormSmartSelect";
import ResourceForm from "@/components/ResourceForm";
import AddressFields from "./AddressFields";
import SaleItemFields from "./SaleItemFields";
import type { SaleFormOptions, SaleFormRecord, SaleItemFormRecord } from "../types";

type SaleFormProps = {
  isNew: boolean;
  options: SaleFormOptions;
  sale: SaleFormRecord;
  submitLabel: string;
};

type PageErrors = Record<string, string | undefined>;

function titleize(str: string): string {
  return str.replace(/[-_]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function newSaleItem(): SaleItemFormRecord {
  return { id: null, product_id: null, qty: "", price: "", _destroy: false };
}

export default function SaleForm({ isNew, options, sale, submitLabel }: SaleFormProps) {
  const [customerId, setCustomerId] = useState<number | null>(sale.customer_id);
  const saleItems = useDynamicSection(sale.sale_items, newSaleItem);

  const action = isNew ? "/sales" : sale.path;
  const method = isNew ? "post" : "patch";

  return (
    <ResourceForm action={action} cancelHref="/sales" method={method} submitLabel={submitLabel}>
      {({ errors }) => {
        const pageErrors = (errors ?? {}) as PageErrors;
        const customerError = pageErrors.customer ?? pageErrors.customer_id;

        return (
          <>
            <section className="form_section_item">
              <label htmlFor="sale[status]" className="font-semibold">
                E-Commerce Order Status
              </label>
              <div className="flex flex-wrap gap-4 mt-4">
                {options.status_names.map((statusName) => (
                  <div className="flex items-center mr-2" key={statusName}>
                    <label className="m-0 p-0 flex items-center relative cursor-pointer">
                      <input
                        className="p-0"
                        defaultChecked={sale.status === statusName}
                        name="sale[status]"
                        type="radio"
                        value={statusName}
                      />
                    </label>
                    <label className="m-0 p-0 pl-2 cursor-pointer text-sm">
                      {titleize(statusName)}
                    </label>
                  </div>
                ))}
              </div>
            </section>

            <FormSmartSelect
              defaultValue={toSelectedOption(options.customers, customerId)}
              error={customerError}
              inputId="sale_customer_id"
              isClearable
              label="Customer"
              name="sale[customer_id]"
              onChange={(option) => setCustomerId(option?.value ?? null)}
              options={options.customers}
            />

            <FormInput defaultValue={sale.note} label="Note" name="sale[note]" />

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

            <DynamicNestedForm name="Product" onAdd={saleItems.add}>
              {saleItems.items.map((saleItem, index) => (
                <SaleItemFields
                  index={index}
                  key={saleItem.clientKey}
                  onRemove={saleItems.remove}
                  productOptions={options.products}
                  saleItem={saleItem}
                />
              ))}
            </DynamicNestedForm>
          </>
        );
      }}
    </ResourceForm>
  );
}
