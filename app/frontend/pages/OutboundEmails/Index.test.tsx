import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePagination } from "@/test/factories";

import Index from "./Index";

const linkedEmail = {
  id: 7,
  recipient: "buyer@example.com",
  recipient_name: "Vasily Kupkin",
  subject: "Order updated",
  product_title: "Golden Figurine",
  product_thumb_url: "/figurine.jpg",
  state: "accepted" as const,
  created_at: "2026-10-13T10:00:00Z",
  accepted_at: "2026-10-13T10:01:00Z",
  path: "/outbound_emails/7",
  customer_path: "/customers/3",
  sale_path: "/sales/1746",
  sale_label: "Sale HSCM#1746",
  purchase_path: "/purchases/55",
  purchase_label: "Purchase 55",
};

describe("OutboundEmails/Index", () => {
  it("shows searchable, paginated records with a link to details", () => {
    render(
      <Index
        outbound_emails={[linkedEmail]}
        pagination={makePagination({ current_page: 1, total_pages: 2, total_count: 26, limit: 25 })}
        search={{ q: "buyer" }}
      />,
    );

    expect(screen.getByRole("searchbox")).toHaveValue("buyer");
    expect(screen.getAllByRole("columnheader").map((header) => header.textContent)).toEqual([
      "EmailStatus guide",
      "Recipient",
      "Product",
    ]);
    expect(screen.getByRole("link", { name: "Order updated" })).toHaveAttribute(
      "href",
      "/outbound_emails/7",
    );
    expect(screen.getAllByRole("link", { name: "2" })[0]).toHaveAttribute(
      "href",
      "/outbound_emails?page=2&q=buyer",
    );
  });

  it("explains every status in everyday language", async () => {
    const user = userEvent.setup();
    render(
      <Index
        outbound_emails={[linkedEmail]}
        pagination={makePagination({ total_count: 1 })}
        search={{ q: "" }}
      />,
    );

    await user.hover(screen.getByText("Status guide"));
    const guide = await screen.findByRole("tooltip");
    expect(guide).toHaveTextContent("Waiting to send: Not sent yet. It is waiting its turn.");
    expect(guide).toHaveTextContent("Handed to email service: Our email service took the message.");
    expect(guide).toHaveTextContent("Test mode — not sent: This was a test. No email was sent.");
  });

  it("links the saved recipient, sale, and purchase", () => {
    render(
      <Index
        outbound_emails={[linkedEmail]}
        pagination={makePagination({ total_count: 1 })}
        search={{ q: "" }}
      />,
    );

    expect(screen.getByRole("link", { name: "Vasily Kupkin" })).toHaveAttribute(
      "href",
      "/customers/3",
    );
    expect(screen.getByRole("link", { name: "Sale HSCM#1746" })).toHaveAttribute(
      "href",
      "/sales/1746",
    );
    expect(screen.getByRole("link", { name: "Purchase 55" })).toHaveAttribute(
      "href",
      "/purchases/55",
    );
  });

  it("shows the recipient name, address, and product photo", () => {
    render(
      <Index
        outbound_emails={[linkedEmail]}
        pagination={makePagination({ total_count: 1 })}
        search={{ q: "" }}
      />,
    );

    expect(screen.getByText("Vasily Kupkin")).toBeInTheDocument();
    expect(screen.getByText("buyer@example.com")).toBeInTheDocument();
    expect(screen.getByText("Golden Figurine")).toBeInTheDocument();
    expect(screen.getByRole("img", { name: "Golden Figurine" })).toHaveAttribute(
      "src",
      "/figurine.jpg",
    );
  });

  it("explains an empty email history", () => {
    render(
      <Index
        outbound_emails={[]}
        pagination={makePagination({ total_count: 0 })}
        search={{ q: "" }}
      />,
    );
    expect(screen.getByText("No emails to show yet.")).toBeInTheDocument();
  });

  it("handles older emails without a saved name or product photo", () => {
    render(
      <Index
        outbound_emails={[
          {
            id: 8,
            recipient: "buyer@example.com",
            recipient_name: null,
            subject: "Order updated",
            product_title: null,
            product_thumb_url: null,
            state: "simulated",
            created_at: "2026-10-13T10:00:00Z",
            accepted_at: null,
            path: "/outbound_emails/8",
            customer_path: null,
            sale_path: null,
            sale_label: null,
            purchase_path: null,
            purchase_label: null,
          },
        ]}
        pagination={makePagination({ total_count: 1 })}
        search={{ q: "" }}
      />,
    );

    expect(screen.getByText("Name not recorded")).toBeInTheDocument();
    expect(screen.getByText("Product name not recorded")).toBeInTheDocument();
    expect(screen.queryByRole("img")).not.toBeInTheDocument();
    expect(screen.getByText("Test mode — not sent")).toBeInTheDocument();
  });
});
