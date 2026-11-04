import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form from "./components/Form";
import { VersionFormRecord } from "./types";

type NewProps = {
  version: VersionFormRecord;
};

export default function New({ version }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Version" />

      <Form
        method="post"
        submitLabel="Create Version"
        url={routes.versions.create.path()}
        version={version}
      />
    </>
  );
}
