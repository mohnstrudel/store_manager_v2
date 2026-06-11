import ResourceIndexPage from "@/components/ResourceIndexPage";
import routes from "@/utils/routes";
import Table from "./components/Table";
import { SupplierRecord } from "./types";

type IndexProps = {
  suppliers: SupplierRecord[];
};

export default function Index({ suppliers }: IndexProps) {
  return (
    <ResourceIndexPage newPath={routes.suppliers.new.path()} title="Suppliers">
      <Table suppliers={suppliers} />
    </ResourceIndexPage>
  );
}
