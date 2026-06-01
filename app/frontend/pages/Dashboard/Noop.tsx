import PageHeader from "@/components/PageHeader";

export default function Noop() {
  return (
    <>
      <PageHeader title="Dashboard" />

      <section className="section_border_base section_wide text-center">
        <p className="text-gray-600 dark:text-gray-300">Nothing else needs your attention here.</p>
      </section>
    </>
  );
}
