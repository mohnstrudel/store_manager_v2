import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { ShippingCompanyErrors, ShippingCompanyRecord } from "../types";

type ShippingCompanyFormProps = {
  errors?: ShippingCompanyErrors;
  method: "post" | "patch";
  submitLabel: string;
  shippingCompany: ShippingCompanyRecord;
  url: string;
};

export default function Form({
  errors = {},
  method,
  submitLabel,
  shippingCompany,
  url,
}: ShippingCompanyFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    shipping_company: {
      name: shippingCompany.name,
      tracking_url: shippingCompany.tracking_url ?? "",
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
    <>
      <ErrorNotice errors={errors} />
      <ResourceForm
        cancelHref="/shipping_companies"
        onSubmit={submit}
        submitDisabled={processing}
        submitLabel={submitLabel}
      >
        <FormField
          error={errors.name}
          label="Name"
          name="name"
          namespace="shipping_company"
          onChange={(name) =>
            setData("shipping_company", {
              ...data.shipping_company,
              name,
            })
          }
          value={data.shipping_company.name}
        />
        <FormField
          error={errors.tracking_url}
          label="Tracking URL"
          name="tracking_url"
          namespace="shipping_company"
          onChange={(tracking_url) =>
            setData("shipping_company", {
              ...data.shipping_company,
              tracking_url,
            })
          }
          type="url"
          value={data.shipping_company.tracking_url}
        />
      </ResourceForm>
    </>
  );
}
