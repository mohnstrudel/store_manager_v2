import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { router } from "@inertiajs/react";
import SearchBar from "./SearchBar";

describe("SearchBar", () => {
  it("renders the search input with the initial query", () => {
    renderSearchBar({ initialQuery: "pikachu" });

    expect(screen.getByRole("searchbox")).toHaveValue("pikachu");
  });

  it("submits a search request with the typed query", async () => {
    const user = userEvent.setup();
    renderSearchBar();

    await user.clear(screen.getByRole("searchbox"));
    await user.type(screen.getByRole("searchbox"), "charizard");
    await user.click(screen.getByRole("button", { name: /Search/ }));

    expect(router.get).toHaveBeenCalledWith(
      "/products",
      { q: "charizard" },
      expect.objectContaining({ only: ["products", "pagination", "search"], preserveState: true }),
    );
  });

  it("omits the query param when the search input is empty", async () => {
    const user = userEvent.setup();
    renderSearchBar();

    await user.clear(screen.getByRole("searchbox"));
    await user.click(screen.getByRole("button", { name: /Search/ }));

    expect(router.get).toHaveBeenCalledWith("/products", { q: undefined }, expect.anything());
  });

  describe("when there is an active query", () => {
    it("renders an Exit link to clear the search", () => {
      renderSearchBar({ initialQuery: "pikachu" });

      expect(screen.getByRole("link", { name: /Exit/ })).toHaveAttribute("href", "/products");
    });

    it("applies a border highlight to the search input", () => {
      renderSearchBar({ initialQuery: "pikachu" });

      expect(screen.getByRole("searchbox")).toHaveClass("border-2");
    });
  });

  describe("when there is no active query", () => {
    it("does not render the Exit link", () => {
      renderSearchBar({ initialQuery: "" });

      expect(screen.queryByRole("link", { name: /Exit/ })).not.toBeInTheDocument();
    });
  });
});

type RenderSearchBarOptions = {
  initialQuery?: string;
  path?: string;
  resourceName?: string;
};

function renderSearchBar({
  initialQuery = "",
  path = "/products",
  resourceName = "products",
}: RenderSearchBarOptions = {}) {
  return render(<SearchBar initialQuery={initialQuery} path={path} resourceName={resourceName} />);
}
