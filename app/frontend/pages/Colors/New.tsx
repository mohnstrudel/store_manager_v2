import Form from "./components/Form";
import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import { ColorErrors, ColorRecord } from "./types";

type NewProps = {
  color: ColorRecord;
  errors?: ColorErrors;
};

export default function New({ color, errors = {} }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Color" />

      <Form color={color} errors={errors} method="post" submitLabel="Create Color" url="/colors" />
    </>
  );
}
