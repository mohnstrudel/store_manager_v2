import { Link } from "@inertiajs/react";
import type { ReactNode } from "react";

import PageHeader from "@/components/PageHeader";

type ResourceIndexPageProps = {
  bordered?: boolean;
  children: ReactNode;
  newOpensModal?: boolean;
  newPath?: string;
  title: ReactNode;
};

export default function ResourceIndexPage({
  bordered = true,
  children,
  newOpensModal,
  newPath,
  title,
}: ResourceIndexPageProps) {
  return (
    <>
      <PageHeader title={title}>
        {newPath ? (
          <li>
            <Link
              href={newPath}
              preserveScroll={newOpensModal}
              preserveState={newOpensModal}
              prefetch
            >
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        ) : null}
      </PageHeader>

      <section className={bordered ? "section_border_base section_wide" : "section_wide"}>
        {children}
      </section>
    </>
  );
}
