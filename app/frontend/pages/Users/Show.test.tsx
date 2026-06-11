import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";
import { makeUser } from "./test/factories";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Users/Show", () => {
  it("renders the user details and edit link", () => {
    renderShow();

    expect(
      screen.getByRole("heading", { name: "ash@example.com" })
    ).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/users/1/edit"
    );
    expect(screen.getByRole("cell", { name: "Ash" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "Ketchum" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "manager" })).toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the user after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this user" })
      );

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/users/1");
    });

    it("does not destroy the user when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this user" })
      );

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({ user = makeUser() } = {}) {
  return render(<Show user={user} />);
}
