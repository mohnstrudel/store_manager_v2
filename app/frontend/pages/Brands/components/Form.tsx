import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { BrandErrors, BrandRecord } from "../types";

type BrandFormProps = {
  brand: BrandRecord;
  errors?: BrandErrors;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ brand, errors = {}, method, submitLabel, url }: BrandFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    brand: {
      title: brand.title,
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
        cancelHref="/brands"
        onSubmit={submit}
        submitDisabled={processing}
        submitLabel={submitLabel}
      >
        <FormField
          error={errors.title}
          label="Title"
          name="title"
          namespace="brand"
          onChange={(title) => setData("brand", { ...data.brand, title })}
          value={data.brand.title}
        />
      </ResourceForm>
    </>
  );
}
