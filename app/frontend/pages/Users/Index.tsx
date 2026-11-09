import ResourceIndexPage from "@/components/ResourceIndexPage";
import type { UsersIndex } from "@/types/serializers";

import IndexTable from "./components/IndexTable";

type IndexProps = UsersIndex;

export default function Index({ users }: IndexProps) {
  return (
    <ResourceIndexPage title="Users">
      <IndexTable users={users} />
    </ResourceIndexPage>
  );
}
