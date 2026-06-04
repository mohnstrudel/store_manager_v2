import { getFormString } from "@/lib/formSchema";
import { msg } from "@/lib/validationMessages";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { FranchiseRecord } from "../types";

type FranchiseFormProps = {
  franchise: FranchiseRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

function validate(formData: FormData) {
  return getFormString(formData, "franchise[title]").trim() ? null : { title: msg.blank };
}

export default function Form({ franchise, method, submitLabel, url }: FranchiseFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref="/franchises"
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <FormInput
          defaultValue={franchise.title}
          error={errors.title}
          label="Title"
          name="franchise[title]"
        />
      )}
    </ResourceForm>
  );
}
