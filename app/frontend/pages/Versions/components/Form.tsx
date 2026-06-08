import { getFormString } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { VersionRecord } from "../types";

type VersionFormProps = {
  method: "post" | "patch";
  submitLabel: string;
  url: string;
  version: VersionRecord;
};

function validate(formData: FormData) {
  return getFormString(formData, "version[value]").trim() ? null : { value: msg.blank };
}

export default function Form({ method, submitLabel, url, version }: VersionFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref="/versions"
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <FormInput
          defaultValue={version.value}
          error={errors.value}
          label="Value"
          name="version[value]"
        />
      )}
    </ResourceForm>
  );
}
