import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { FranchiseErrors, FranchiseRecord } from "../types";

type FranchiseFormProps = {
  errors: FranchiseErrors;
  franchise: FranchiseRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({ errors, franchise, method, submitLabel, url }: FranchiseFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    franchise: {
      title: franchise.title,
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
      <ResourceForm cancelHref="/franchises" onSubmit={submit} submitDisabled={processing} submitLabel={submitLabel}>
        <FormField
          error={errors.title}
          label="Title"
          name="title"
          namespace="franchise"
          onChange={(title) => setData("franchise", { ...data.franchise, title })}
          value={data.franchise.title}
        />
      </ResourceForm>
    </>
  );
}
