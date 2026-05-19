import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { ColorErrors, ColorRecord } from "../types";

type ColorFormProps = {
  color: ColorRecord;
  errors: ColorErrors;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ color, errors, method, submitLabel, url }: ColorFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    color: {
      value: color.value,
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
    <>
      <ErrorNotice errors={errors} />
      <ResourceForm cancelHref="/colors" onSubmit={submit} submitDisabled={processing} submitLabel={submitLabel}>
        <FormField
          error={errors.value}
          label="Value"
          name="value"
          namespace="color"
          onChange={(value) => setData("color", { ...data.color, value })}
          value={data.color.value}
        />
      </ResourceForm>
    </>
  );
}
