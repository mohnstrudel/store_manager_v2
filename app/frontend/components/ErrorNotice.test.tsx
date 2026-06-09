import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import ErrorNotice from "./ErrorNotice";

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ props: { errors: {} } }),
}));

describe("ErrorNotice", () => {
  it("renders a full-width notice for client and server errors", () => {
    render(<ErrorNotice errors={{ title: "can't be blank" }} />);

    expect(screen.getByText("Fix errors and try again").closest("article")).toHaveClass("w-full");
  });
});
