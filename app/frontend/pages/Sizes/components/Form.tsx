import { FormEvent } from "react";
import { useForm } from "@inertiajs/react";
import Button from "@/components/Button";
import FormField from "@/components/FormField";
import Link from "@/components/Link";
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
    <form onSubmit={submit}>
      <FormField
        error={errors.value}
        label="Value"
        name="value"
        onChange={(value) => setData("size", { ...data.size, value })}
        value={data.size.value}
      />

      <div className="flex flex-col gap-4 items-start justify-start mt-14 lg:flex-row lg:items-center">
        <Button className="w-full lg:w-fit" disabled={processing} type="submit" variant="primary">
          {submitLabel}
        </Button>
        <Link className="w-full lg:w-fit h-10" href="/sizes">
          Cancel
        </Link>
      </div>
    </form>
  );
}
