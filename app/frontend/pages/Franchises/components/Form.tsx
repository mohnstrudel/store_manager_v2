import { usePage } from "@inertiajs/react";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { FranchiseRecord } from "../types";

type FranchiseFormProps = {
  franchise: FranchiseRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ franchise, method, submitLabel, url }: FranchiseFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm action={url} cancelHref="/franchises" method={method} submitLabel={submitLabel}>
      <FormInput
        defaultValue={franchise.title}
        error={errors.title}
        label="Title"
        name="franchise[title]"
      />
    </ResourceForm>
  );
}
