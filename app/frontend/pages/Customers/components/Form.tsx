import { usePage } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { CustomerRecord } from "../types";

type CustomerFormProps = {
  customer: CustomerRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ customer, method, submitLabel, url }: CustomerFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm action={url} cancelHref="/customers" method={method} submitLabel={submitLabel}>
      <fieldset className="flex justify-between gap-4 flex-col lg:flex-row lg:-mt-8">
        <div className="block w-full">
          <FormField
            defaultValue={customer.first_name}
            error={errors.first_name}
            label="First name"
            name="customer[first_name]"
          />
        </div>
        <div className="block w-full">
          <FormField
            defaultValue={customer.last_name}
            error={errors.last_name}
            label="Last name"
            name="customer[last_name]"
          />
        </div>
      </fieldset>
      <fieldset className="flex justify-between gap-4 flex-col lg:flex-row">
        <div className="block w-full">
          <FormField
            defaultValue={customer.email}
            error={errors.email}
            label="Email"
            name="customer[email]"
            type="email"
          />
        </div>
        <div className="block w-full">
          <FormField
            defaultValue={customer.phone}
            error={errors.phone}
            label="Phone"
            name="customer[phone]"
          />
        </div>
      </fieldset>
    </ResourceForm>
  );
}
