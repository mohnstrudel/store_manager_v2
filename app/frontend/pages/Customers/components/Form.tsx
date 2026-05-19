import { type FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { CustomerErrors, CustomerRecord } from "../types";

type CustomerFormProps = {
  customer: CustomerRecord;
  errors?: CustomerErrors;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ customer, errors = {}, method, submitLabel, url }: CustomerFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    customer: {
      first_name: customer.first_name,
      last_name: customer.last_name,
      email: customer.email,
      phone: customer.phone,
    },
  });

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (method === "patch") {
      patch(url);
    } else {
      post(url);
    }
  }

  return (
    <ResourceForm
      cancelHref="/customers"
      onSubmit={submit}
      submitDisabled={processing}
      submitLabel={submitLabel}
    >
      <fieldset className="flex justify-between gap-4 flex-col lg:flex-row lg:-mt-8">
        <div className="block w-full">
          <FormField
            error={errors.first_name}
            label="First name"
            name="first_name"
            namespace="customer"
            onChange={(value) => setData("customer", { ...data.customer, first_name: value })}
            value={data.customer.first_name}
          />
        </div>
        <div className="block w-full">
          <FormField
            error={errors.last_name}
            label="Last name"
            name="last_name"
            namespace="customer"
            onChange={(value) => setData("customer", { ...data.customer, last_name: value })}
            value={data.customer.last_name}
          />
        </div>
      </fieldset>

      <fieldset className="flex justify-between gap-4 flex-col lg:flex-row">
        <div className="block w-full">
          <FormField
            error={errors.email}
            label="Email"
            name="email"
            namespace="customer"
            onChange={(value) => setData("customer", { ...data.customer, email: value })}
            type="email"
            value={data.customer.email}
          />
        </div>
        <div className="block w-full">
          <FormField
            error={errors.phone}
            label="Phone"
            name="phone"
            namespace="customer"
            onChange={(value) => setData("customer", { ...data.customer, phone: value })}
            value={data.customer.phone}
          />
        </div>
      </fieldset>
    </ResourceForm>
  );
}
