import { usePage } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import { PageProps } from "@/types/inertia";

export default function HelloIndex() {
  const { auth } = usePage<PageProps>().props;

  return (
    <>
      <PageHeader title="Inertia + React is working" />

      <section className="section_border_base section_wide">
        <p className="text-gray-600">
          Signed in as: {auth?.user?.email_address ?? "not authenticated"}
        </p>
      </section>
    </>
  );
}
