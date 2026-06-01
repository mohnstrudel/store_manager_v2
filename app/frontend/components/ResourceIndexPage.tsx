import { Link } from "@inertiajs/react";
import type { ReactNode } from "react";
import PageHeader from "@/components/PageHeader";

type ResourceIndexPageProps = {
  children: ReactNode;
  newPath?: string;
  title: ReactNode;
};

export default function ResourceIndexPage({ children, newPath, title }: ResourceIndexPageProps) {
  return (
    <>
      <PageHeader title={title}>
        {newPath ? (
          <li>
            <Link href={newPath} prefetch>
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        ) : null}
      </PageHeader>

      <section className="section_border_base section_wide">{children}</section>
    </>
  );
}
