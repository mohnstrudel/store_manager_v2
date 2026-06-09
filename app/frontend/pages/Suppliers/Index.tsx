import ResourceIndexPage from "@/components/ResourceIndexPage";
import Table from "./components/Table";
import { SupplierRecord } from "./types";

type IndexProps = {
  suppliers: SupplierRecord[];
};

export default function Index({ suppliers }: IndexProps) {
  return (
    <ResourceIndexPage newPath="/suppliers/new" title="Suppliers">
      <Table suppliers={suppliers} />
    </ResourceIndexPage>
  );
}
