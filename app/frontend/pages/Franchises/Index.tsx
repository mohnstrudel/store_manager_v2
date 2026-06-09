import ResourceIndexPage from "@/components/ResourceIndexPage";
import Table from "./components/Table";
import { FranchiseRecord } from "./types";

type IndexProps = {
  franchises: FranchiseRecord[];
};

export default function Index({ franchises }: IndexProps) {
  return (
    <ResourceIndexPage newPath="/franchises/new" title="Franchises">
      <Table franchises={franchises} />
    </ResourceIndexPage>
  );
}
