import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { SupplierErrors, SupplierRecord } from "../types";

type SupplierFormProps = {
  errors?: SupplierErrors;
  method: "post" | "patch";
  submitLabel: string;
  supplier: SupplierRecord;
  url: string;
};

export default function Form({
  errors = {},
  method,
  submitLabel,
  supplier,
  url,
}: SupplierFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    supplier: {
      title: supplier.title,
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
      <ResourceForm
        cancelHref="/suppliers"
        onSubmit={submit}
        submitDisabled={processing}
        submitLabel={submitLabel}
      >
        <FormField
          error={errors.title}
          label="Title"
          name="title"
          namespace="supplier"
          onChange={(title) => setData("supplier", { ...data.supplier, title })}
          value={data.supplier.title}
        />
      </ResourceForm>
    </>
  );
}
