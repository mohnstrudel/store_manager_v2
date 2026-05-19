import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { FranchiseErrors, FranchiseRecord } from "./types";

type NewProps = {
  errors?: FranchiseErrors;
  franchise: FranchiseRecord;
};

export default function New({ errors = {}, franchise }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Franchise" />

      <Form
        errors={errors}
        franchise={franchise}
        method="post"
        submitLabel="Create Franchise"
        url="/franchises"
      />
    </>
  );
}
