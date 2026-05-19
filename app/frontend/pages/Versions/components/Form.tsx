import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { VersionErrors, VersionRecord } from "../types";

type VersionFormProps = {
  errors: VersionErrors;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
  version: VersionRecord;
};

export default function Form({ errors, method, submitLabel, url, version }: VersionFormProps) {
  const { data, patch, post, processing, setData } = useForm({
    version: {
      value: version.value,
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
      <ResourceForm cancelHref="/versions" onSubmit={submit} submitDisabled={processing} submitLabel={submitLabel}>
        <FormField
          error={errors.value}
          label="Value"
          name="value"
          namespace="version"
          onChange={(value) => setData("version", { ...data.version, value })}
          value={data.version.value}
        />
      </ResourceForm>
    </>
  );
}
