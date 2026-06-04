import { getFormString } from "@/lib/formSchema";
import { msg } from "@/lib/validationMessages";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { SizeRecord } from "../types";

type SizeFormProps = {
  method: "post" | "patch";
  size: SizeRecord;
  submitLabel: string;
  url: string;
};

function validate(formData: FormData) {
  return getFormString(formData, "size[value]").trim() ? null : { value: msg.blank };
}

export default function Form({ method, size, submitLabel, url }: SizeFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref="/sizes"
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <FormInput
          defaultValue={size.value}
          error={errors.value}
          label="Value"
          name="size[value]"
        />
      )}
    </ResourceForm>
  );
}
