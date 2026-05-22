import { usePage } from "@inertiajs/react";
import { PageProps } from "@/types/inertia";

export default function HelloIndex() {
  const { auth } = usePage<PageProps>().props;

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Inertia + React is working</h1>
      <p className="text-gray-600">
        Signed in as: {auth?.user?.email_address ?? "not authenticated"}
      </p>
    </div>
  );
}
