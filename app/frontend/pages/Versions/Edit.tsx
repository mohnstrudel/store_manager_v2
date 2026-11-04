import { Link } from "@inertiajs/react";
import { FileTextIcon } from "lucide-react";

import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form from "./components/Form";
import { VersionFormRecord } from "./types";

type EditProps = {
  version: VersionFormRecord;
};

export default function Edit({ version }: EditProps) {
  const currentVersionPath = routes.versions.show.path({ id: version.id! });

  return (
    <>
      <PageHeader className="mb-8" title="Edit Version">
        <li>
          <Link href={currentVersionPath} prefetch>
            <FileTextIcon />
            View Version Page
          </Link>
        </li>
      </PageHeader>

      <Form
        method="patch"
        submitLabel="Update Version"
        url={currentVersionPath}
        version={version}
      />
    </>
  );
}
