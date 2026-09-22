import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import MetricLabel from "./MetricLabel";

describe("MetricLabel", () => {
  it("renders its label with the shared hover-tip treatment", () => {
    render(
      <MetricLabel anchor="revenue" hint="A plain explanation.">
        Revenue
      </MetricLabel>,
    );

    expect(screen.getByText("Revenue")).toBeInTheDocument();
    expect(screen.getByLabelText("More information")).toHaveTextContent("*");
  });

  it("links its tip to the term's entry on the glossary page", async () => {
    const user = userEvent.setup();
    render(
      <MetricLabel anchor="revenue" hint="A plain explanation.">
        Revenue
      </MetricLabel>,
    );

    await user.hover(screen.getByLabelText("More information"));
    await act(async () => {});

    expect(screen.getByText("A plain explanation.")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Glossary" })).toHaveAttribute(
      "href",
      "/glossary#revenue",
    );
  });

  it("points the glossary link at the anchor for the term shown", async () => {
    const user = userEvent.setup();
    render(
      <MetricLabel anchor="cashPositionToday" hint="A plain explanation.">
        Cash today
      </MetricLabel>,
    );

    await user.hover(screen.getByLabelText("More information"));
    await act(async () => {});

    expect(screen.getByRole("link", { name: "Glossary" })).toHaveAttribute(
      "href",
      "/glossary#cashPositionToday",
    );
  });

  it("makes the whole label the hover/focus target and drops the mark when hoverWhole is set", async () => {
    const user = userEvent.setup();
    render(
      <MetricLabel anchor="revenue" hint="A plain explanation." hoverWhole>
        Revenue
      </MetricLabel>,
    );

    expect(screen.queryByLabelText("More information")).not.toBeInTheDocument();

    await user.hover(screen.getByText("Revenue"));
    await act(async () => {});

    expect(screen.getByText("A plain explanation.")).toBeInTheDocument();
  });
});
