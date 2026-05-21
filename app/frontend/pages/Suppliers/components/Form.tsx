import { usePage } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { SupplierRecord } from "../types";

type SupplierFormProps = {
  method: "post" | "patch";
  submitLabel: string;
  supplier: SupplierRecord;
  url: string;
};

export default function Form({ method, submitLabel, supplier, url }: SupplierFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm action={url} cancelHref="/suppliers" method={method} submitLabel={submitLabel}>
      <FormField defaultValue={supplier.title} error={errors.title} label="Title" name="supplier[title]" />
    </ResourceForm>
  );
}
