import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { getFormString } from "@/utils/formSchema";
import routes from "@/utils/routes";
import { msg } from "@/utils/validationMessages";

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
      cancelHref={routes.franchises.index.path()}
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
