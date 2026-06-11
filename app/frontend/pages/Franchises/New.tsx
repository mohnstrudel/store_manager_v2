import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import Form from "./components/Form";
import { FranchiseRecord } from "./types";

type NewProps = {
  franchise: FranchiseRecord;
};

export default function New({ franchise }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Franchise" />
      <Form
        franchise={franchise}
        method="post"
        submitLabel="Create Franchise"
        url={routes.franchises.create.path()}
      />
    </>
  );
}
