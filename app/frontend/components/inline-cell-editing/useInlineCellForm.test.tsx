import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import routes from "@/utils/routes";
import { useInlineCellForm } from "./useInlineCellForm";

describe("useInlineCellForm", () => {
  it("uses an optional generic reload-props list for the Inertia patch", async () => {
    const user = userEvent.setup();

    render(<Harness />);

    await user.click(screen.getByRole("button", { name: "Save value" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/variant_assignment_issues/purchases/7",
      {
        purchase: { variant_id: "11" },
        return_to: "/",
      },
      expect.objectContaining({
        only: ["issues", "counts", "pagination"],
        preserveScroll: true,
      }),
    );
  });
});

function Harness() {
  const form = useInlineCellForm({
    editedRecord: { id: 7, variant_id: 11 },
    attributeName: "variant_id",
    route: routes.variantAssignmentIssuesPurchases.update,
    collection: "issues",
    paramKey: "purchase",
    idParam: "id",
    reloadProps: ["issues", "counts", "pagination"],
  });

  return (
    <button onClick={form.save} type="button">
      Save value
    </button>
  );
}
