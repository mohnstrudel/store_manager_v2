import { usePage } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { BrandRecord } from "../types";

type BrandFormProps = {
  brand: BrandRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ brand, method, submitLabel, url }: BrandFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm action={url} cancelHref="/brands" method={method} submitLabel={submitLabel}>
      <FormField defaultValue={brand.title} error={errors.title} label="Title" name="brand[title]" />
    </ResourceForm>
  );
}
