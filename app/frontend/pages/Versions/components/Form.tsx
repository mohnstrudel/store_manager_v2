import { usePage } from "@inertiajs/react";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { VersionRecord } from "../types";

type VersionFormProps = {
  method: "post" | "patch";
  submitLabel: string;
  url: string;
  version: VersionRecord;
};

export default function Form({ method, submitLabel, url, version }: VersionFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm action={url} cancelHref="/versions" method={method} submitLabel={submitLabel}>
      <FormInput
        defaultValue={version.value}
        error={errors.value}
        label="Value"
        name="version[value]"
      />
    </ResourceForm>
  );
}
