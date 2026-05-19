import ErrorNotice from "@/components/ErrorNotice";
import Form from "./components/Form";
import { FranchiseErrors, FranchiseRecord } from "./types";

type NewProps = {
  errors: FranchiseErrors;
  franchise: FranchiseRecord;
};

export default function New({ errors, franchise }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>New Franchise</h1>
        </div>
      </header>

      <Form errors={errors} franchise={franchise} method="post" submitLabel="Create Franchise" url="/franchises" />
    </>
  );
}
