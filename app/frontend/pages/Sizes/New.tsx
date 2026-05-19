import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { SizeErrors, SizeRecord } from "./types";

type NewProps = {
  errors?: SizeErrors;
  size: SizeRecord;
};

export default function New({ errors = {}, size }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Size" />

      <Form errors={errors} method="post" size={size} submitLabel="Create Size" url="/sizes" />
    </>
  );
}
