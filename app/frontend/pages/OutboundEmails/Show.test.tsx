import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Show from "./Show";

const email = {
  id: 7,
  recipient: "buyer@example.com",
  recipient_name: "Vasily Kupkin",
  sender: "shop@example.com",
  subject: "Order updated",
  body: "Hello <script>alert(1)</script>\nYour order moved.",
  product_title: "Golden Figurine",
  product_thumb_url: "/figurine.jpg",
  state: "accepted" as const,
  attempts: 1,
  last_attempt_at: "2026-10-13T10:01:00Z",
  last_error: null,
  accepted_at: "2026-10-13T10:01:00Z",
  created_at: "2026-10-13T10:00:00Z",
};

describe("OutboundEmails/Show", () => {
  it("renders the saved body as text and labels acceptance accurately", () => {
    const { container } = render(<Show outbound_email={email} />);

    expect(
      screen.getByText(
        "Our email service took the message. We do not know if it reached the inbox.",
      ),
    ).toBeInTheDocument();
    expect(screen.getByText(/Hello <script>alert\(1\)<\/script>/)).toBeInTheDocument();
    expect(container.querySelector("script")).toBeNull();
    expect(screen.getByRole("link", { name: "Email History" })).toHaveAttribute(
      "href",
      "/outbound_emails",
    );
  });

  it("shows the recipient and product next to the saved email", () => {
    render(<Show outbound_email={email} />);

    expect(screen.getByText("Vasily Kupkin")).toBeInTheDocument();
    expect(screen.getByText("buyer@example.com")).toBeInTheDocument();
    expect(screen.getByText("Golden Figurine")).toBeInTheDocument();
    expect(screen.getByRole("img", { name: "Golden Figurine" })).toHaveAttribute(
      "src",
      "/figurine.jpg",
    );
  });

  it("separates delivery details from a mail-style message preview", () => {
    render(<Show outbound_email={email} />);

    const preview = screen.getByRole("region", { name: "Email preview" });
    expect(within(preview).getByRole("heading", { name: "Order updated" })).toBeInTheDocument();
    expect(within(preview).getByText("shop@example.com")).toBeInTheDocument();
    expect(within(preview).getByText(/Your order moved/)).toBeInTheDocument();
    expect(within(preview).queryByText("Sending attempts")).not.toBeInTheDocument();
  });

  it("explains when a record has no saved email text", () => {
    render(
      <Show
        outbound_email={{
          ...email,
          body: null,
          recipient: null,
          state: "simulated",
          last_attempt_at: null,
          accepted_at: null,
        }}
      />,
    );

    expect(screen.getByText("Email text was not recorded.")).toBeInTheDocument();
    expect(screen.queryByText("Last send attempt")).not.toBeInTheDocument();
    expect(screen.queryByText("Handed to email service")).not.toBeInTheDocument();
  });
});
