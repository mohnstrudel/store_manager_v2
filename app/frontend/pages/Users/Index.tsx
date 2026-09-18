import ResourceIndexPage from "@/components/ResourceIndexPage";

import IndexTable, { type UserRecord } from "./components/IndexTable";

type IndexProps = {
  users: UserRecord[];
};

export default function Index({ users }: IndexProps) {
  return (
    <ResourceIndexPage title="Users">
      <IndexTable users={users} />
    </ResourceIndexPage>
  );
}
