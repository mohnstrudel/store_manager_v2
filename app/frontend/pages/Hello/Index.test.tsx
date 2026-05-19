import { render, screen } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({
    props: {
      auth: { user: { id: 1, email_address: "test@example.com", role: "admin" } },
      flash: { notice: null, alert: null },
      csrf_token: "token",
    },
  }),
}));

import HelloIndex from "./Index";

describe("Hello/Index", () => {
  it("renders the heading", () => {
    render(<HelloIndex />);
    expect(screen.getByText("Inertia + React is working")).toBeInTheDocument();
  });

  it("shows the signed-in user's email", () => {
    render(<HelloIndex />);
    expect(screen.getByText(/test@example\.com/)).toBeInTheDocument();
  });
});
