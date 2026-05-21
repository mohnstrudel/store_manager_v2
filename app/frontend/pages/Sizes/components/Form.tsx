import { usePage } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { SizeRecord } from "../types";

type SizeFormProps = {
  method: "post" | "patch";
  size: SizeRecord;
  submitLabel: string;
  url: string;
};

export default function Form({ method, size, submitLabel, url }: SizeFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm action={url} cancelHref="/sizes" method={method} submitLabel={submitLabel}>
      <FormField defaultValue={size.value} error={errors.value} label="Value" name="size[value]" />
    </ResourceForm>
  );
}
