import { Link } from "@inertiajs/react";
import { FileTextIcon } from "lucide-react";

import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import type { SalesForm } from "@/types/serializers";

import Form from "./components/Form";

type EditProps = SalesForm;

export default function Edit({ options, sale }: EditProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="Edit Sale">
        <li>
          <Link href={sale.path} prefetch>
            <FileTextIcon />
            View Sale
          </Link>
        </li>
      </PageHeader>

      <Form isNew={false} options={options} sale={sale} submitLabel="Update Sale" />
    </>
  );
}
