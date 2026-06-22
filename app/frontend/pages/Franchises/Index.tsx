import ResourceIndexPage from "@/components/ResourceIndexPage";
import routes from "@/utils/routes";
import Table from "./components/Table";
import { FranchiseRecord } from "./types";

type IndexProps = {
  franchises: FranchiseRecord[];
};

export default function Index({ franchises }: IndexProps) {
  return (
    <ResourceIndexPage newPath={routes.franchises.new.path()} title="Franchises">
      <Table franchises={franchises} />
    </ResourceIndexPage>
  );
}
