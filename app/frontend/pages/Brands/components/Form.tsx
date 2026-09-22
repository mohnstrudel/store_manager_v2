import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { getFormString } from "@/utils/formSchema";
import routes from "@/utils/routes";
import { msg } from "@/utils/validationMessages";

import { BrandRecord } from "../types";

type BrandFormProps = {
  brand: BrandRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

function validate(formData: FormData) {
  return getFormString(formData, "brand[title]").trim() ? null : { title: msg.blank };
}

export default function Form({ brand, method, submitLabel, url }: BrandFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref={routes.brands.index.path()}
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <FormInput
          defaultValue={brand.title}
          error={errors.title}
          label="Title"
          name="brand[title]"
        />
      )}
    </ResourceForm>
  );
}
