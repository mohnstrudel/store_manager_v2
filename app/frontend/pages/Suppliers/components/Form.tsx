import { getFormString } from "@/utils/formSchema";
import routes from "@/utils/routes";
import { msg } from "@/utils/validationMessages";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { SupplierRecord } from "../types";

type SupplierFormProps = {
  method: "post" | "patch";
  submitLabel: string;
  supplier: SupplierRecord;
  url: string;
};

function validate(formData: FormData) {
  return getFormString(formData, "supplier[title]").trim()
    ? null
    : { title: msg.blank };
}

export default function Form({
  method,
  submitLabel,
  supplier,
  url,
}: SupplierFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref={routes.suppliers.index.path()}
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <FormInput
          defaultValue={supplier.title}
          error={errors.title}
          label="Title"
          name="supplier[title]"
        />
      )}
    </ResourceForm>
  );
}
