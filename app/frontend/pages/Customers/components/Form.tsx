import { usePage } from "@inertiajs/react";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
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
      <FormRow>
        <FormInput
          defaultValue={customer.first_name}
          error={errors.first_name}
          label="First name"
          name="customer[first_name]"
        />
        <FormInput
          defaultValue={customer.last_name}
          error={errors.last_name}
          label="Last name"
          name="customer[last_name]"
        />
      </FormRow>
      <FormRow>
        <FormInput
          defaultValue={customer.email}
          error={errors.email}
          label="Email"
          name="customer[email]"
          type="email"
        />
        <FormInput
          defaultValue={customer.phone}
          error={errors.phone}
          label="Phone"
          name="customer[phone]"
        />
      </FormRow>
    </ResourceForm>
  );
}
