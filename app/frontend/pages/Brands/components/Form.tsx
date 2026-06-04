import { getFormString } from "@/lib/formSchema";
import { msg } from "@/lib/validationMessages";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
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
      cancelHref="/brands"
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
