import PageHeader from "@/components/PageHeader";

export default function Noop() {
  return (
    <>
      <PageHeader title="Dashboard" />

      <section className="pt-10 flex flex-grow flex-col max-w-120 text-gray-600 dark:text-gray-300">
        <h2>Access Required</h2>
        <p className="text-lg pt-4">
          There is currently no content available because you do not have the required permissions.
        </p>
        <p className="text-lg pt-4">
          If you believe you should have access, please contact the administrator.
        </p>
        <p className="text-lg pt-4">
          Once access has been granted, the relevant content and functionality will become
          available.
        </p>
      </section>
    </>
  );
}
