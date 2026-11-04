import { Link } from "@inertiajs/react";
import { PlusIcon } from "lucide-react";

import PageHeader from "@/components/PageHeader";
import SearchableTableSection from "@/components/SearchableTableSection";
import type { PaginationMeta } from "@/types/pagination";

import Table from "./components/Table";
import { CustomerRecord } from "./types";

type IndexProps = {
  customers: CustomerRecord[];
  pagination: PaginationMeta;
  search: { q: string };
};

export default function Index({ customers, pagination, search }: IndexProps) {
  return (
    <>
      <PageHeader title="Customers">
        <li>
          <Link href="/customers/new" prefetch>
            <PlusIcon />
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <SearchableTableSection
        hasResults={customers.length > 0}
        pagination={pagination}
        path="/customers"
        query={search.q}
        resourceName="customers"
      >
        <Table customers={customers} />
      </SearchableTableSection>
    </>
  );
}
