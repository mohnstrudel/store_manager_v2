import { getFormString } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import routes from "@/utils/routes";
import { ColorRecord } from "../types";

type ColorFormProps = {
  color: ColorRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

function validate(formData: FormData) {
  return getFormString(formData, "color[value]").trim() ? null : { value: msg.blank };
}

export default function Form({ color, method, submitLabel, url }: ColorFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref={routes.colors.index.path()}
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <FormInput
          defaultValue={color.value}
          error={errors.value}
          label="Value"
          name="color[value]"
        />
      )}
    </ResourceForm>
  );
}
