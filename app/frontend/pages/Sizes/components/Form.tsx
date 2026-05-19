import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { SizeErrors, SizeRecord } from "../types";

type SizeFormProps = {
  errors: SizeErrors;
  method: "post" | "patch";
  size: SizeRecord;
  submitLabel: string;
  url: string;
};

export default function Form({ errors, method, size, submitLabel, url }: SizeFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    size: {
      value: size.value,
    },
  });

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (method === "patch") {
      patch(url);
    } else {
      post(url);
    }
  }

  return (
    <ResourceForm cancelHref="/sizes" onSubmit={submit} submitDisabled={processing} submitLabel={submitLabel}>
      <FormField
        error={errors.value}
        label="Value"
        name="value"
        namespace="size"
        onChange={(value) => setData("size", { ...data.size, value })}
        value={data.size.value}
      />
    </ResourceForm>
  );
}
