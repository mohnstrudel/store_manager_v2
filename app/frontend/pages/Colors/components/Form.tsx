import { usePage } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { ColorRecord } from "../types";

type ColorFormProps = {
  color: ColorRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ color, method, submitLabel, url }: ColorFormProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <ResourceForm action={url} cancelHref="/colors" method={method} submitLabel={submitLabel}>
      <FormField
        defaultValue={color.value}
        error={errors.value}
        label="Value"
        name="color[value]"
      />
    </ResourceForm>
  );
}
