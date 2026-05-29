import { usePage } from "@inertiajs/react";
import FormInput from "@/components/FormInput";
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
      <FormInput
        defaultValue={color.value}
        error={errors.value}
        label="Value"
        name="color[value]"
      />
    </ResourceForm>
  );
}
