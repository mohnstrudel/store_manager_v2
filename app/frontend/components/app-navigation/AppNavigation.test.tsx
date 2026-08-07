import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import AppNavigation from "./AppNavigation";

describe("AppNavigation", () => {
  beforeEach(() => {
    mockPageProps({
      auth: {
        user: {
          id: 1,
          email_address: "admin@example.com",
          role: "admin",
        },
      },
    });
  });

  it("renders the main navigation and opens and dismisses the overflow menu", async () => {
    const user = userEvent.setup();

    render(<AppNavigation />);

    const toggle = screen.getByRole("button", {
      name: "More navigation links",
    });

    expect(screen.getByRole("navigation", { name: "Main navigation" })).toBeInTheDocument();
    expect(screen.getByText("StoreMate")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Dashboard" })).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();

    await user.click(toggle);

    expect(screen.getByRole("link", { name: "Brands" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Users" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Log Out" })).toBeInTheDocument();

    fireEvent.pointerDown(document.body);

    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();

    await user.click(toggle);

    expect(screen.getByRole("link", { name: "Brands" })).toBeInTheDocument();

    fireEvent.keyDown(window, { key: "Escape" });

    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();
  });

  it("renders the glossary link for every signed-in role, not just admins", async () => {
    mockPageProps({
      auth: {
        user: {
          id: 1,
          email_address: "manager@example.com",
          role: "manager",
        },
      },
    });
    const user = userEvent.setup();

    render(<AppNavigation />);

    await user.click(screen.getByRole("button", { name: "More navigation links" }));

    expect(screen.getByRole("link", { name: "Glossary" })).toHaveAttribute("href", "/glossary");
  });

  it("renders admin settings links with generated route paths", async () => {
    const user = userEvent.setup();

    render(<AppNavigation />);

    await user.click(screen.getByRole("button", { name: "More navigation links" }));

    expect(screen.getByRole("link", { name: "OpEx Rates" })).toHaveAttribute(
      "href",
      "/expense_rates",
    );
    expect(screen.getByRole("link", { name: "Users" })).toHaveAttribute("href", "/users");
    expect(screen.getByRole("link", { name: "Variant Repairs" })).toHaveAttribute(
      "href",
      "/variant_assignment_issues",
    );
    expect(screen.queryByRole("link", { name: "Analytics" })).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Inventory Planner" })).not.toBeInTheDocument();
  });

  it("closes the overflow menu when a navigation link is selected", async () => {
    const user = userEvent.setup();

    render(<AppNavigation />);

    await user.click(screen.getByRole("button", { name: "More navigation links" }));
    await user.click(screen.getByRole("link", { name: "Brands" }));

    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();
  });

  it("renders a guest-only navigation", () => {
    mockPageProps({
      auth: {
        user: {
          id: 1,
          email_address: "guest@example.com",
          role: "guest",
        },
      },
    });

    render(<AppNavigation />);

    expect(screen.queryByRole("button", { name: "More navigation links" })).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Dashboard" })).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Log Out" })).toBeInTheDocument();
  });
});
