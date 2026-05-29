import { usePage } from "@inertiajs/react";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { ShippingCompanyRecord } from "../types";

type ShippingCompanyFormProps = {
  method: "post" | "patch";
  shippingCompany: ShippingCompanyRecord;
  submitLabel: string;
  url: string;
};

export default function Form({
  method,
  shippingCompany,
  submitLabel,
  url,
}: ShippingCompanyFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm
      action={url}
      cancelHref="/shipping_companies"
      method={method}
      submitLabel={submitLabel}
    >
      <FormInput
        defaultValue={shippingCompany.name}
        error={errors.name}
        label="Name"
        name="shipping_company[name]"
      />
      <FormInput
        defaultValue={shippingCompany.tracking_url ?? ""}
        error={errors.tracking_url}
        label="Tracking URL"
        name="shipping_company[tracking_url]"
        type="url"
      />
    </ResourceForm>
  );
}
