import { getFormString } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import ResourceForm from "@/components/ResourceForm";
import { ShippingCompanyRecord } from "../types";

type ShippingCompanyFormProps = {
  method: "post" | "patch";
  shippingCompany: ShippingCompanyRecord;
  submitLabel: string;
  url: string;
};

function validate(formData: FormData) {
  return getFormString(formData, "shipping_company[tracking_url]").trim()
    ? null
    : { tracking_url: msg.blank };
}

export default function Form({
  method,
  shippingCompany,
  submitLabel,
  url,
}: ShippingCompanyFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref="/shipping_companies"
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <FormRow>
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
        </FormRow>
      )}
    </ResourceForm>
  );
}
