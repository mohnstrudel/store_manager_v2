# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::MediaImportable do
  include Helpers::QueryCounter
  include Helpers::ShopifyMediaScenarios

  let(:product) { create(:product) }

  def stub_cdn(url, bytes)
    stub_request(:get, url).to_return(status: 200, body: bytes, headers: {"Content-Type" => "image/jpeg"})
  end

  def stub_missing_cdn(url)
    stub_request(:get, url).to_return(status: 404)
  end

  def import(*nodes, **options)
    product.import_shopify_media(parsed_media: nodes, **options)
  end

  def stored_checksum(media)
    media.reload.image.blob.checksum
  end

  describe "#import_shopify_media" do
    it "clears local media when parsed_media is blank" do
      create_list(:media, 2, mediaable: product)

      expect {
        product.import_shopify_media(parsed_media: [])
      }.to change { product.media.count }.from(2).to(0)
    end

    context "when a node matches a row by Shopify ID" do
      it "downloads nothing and updates alt and position when the URL is unchanged" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"), alt: "Old", position: 3)

        import(media_node(1, name: "one", alt: "New", position: 0))

        expect(a_request(:get, cdn_url("one"))).not_to have_been_made
        expect(media.reload).to have_attributes(alt: "New", position: 0)
        expect(media.shopify_info).to have_attributes(alt_text: "New", source_url: cdn_url("one"))
      end

      it "downloads nothing and stores the URL when the row has no source_url" do
        media = pulled_media("one", number: 1, source_url: nil)
        blob_id = media.image.blob.id

        import(media_node(1, name: "one"))

        expect(a_request(:get, cdn_url("one"))).not_to have_been_made
        expect(media.reload.shopify_info).to have_attributes(source_url: cdn_url("one"), checksum: image_checksum("one"))
        expect(media.image.blob.id).to eq(blob_id)
      end

      it "downloads the whole URL when only the version query changed and keeps identical bytes" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one", version: 1))
        blob_id = media.image.blob.id
        stub_cdn(cdn_url("one", version: 2), "one")

        import(media_node(1, name: "one", version: 2))

        expect(a_request(:get, cdn_url("one", version: 2))).to have_been_made.once
        expect(media.reload.image.blob.id).to eq(blob_id)
        expect(media.shopify_info).to have_attributes(source_url: cdn_url("one", version: 2), checksum: image_checksum("one"))
      end

      it "replaces the attachment on the same row when the changed URL serves different bytes" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one", version: 1))
        stub_cdn(cdn_url("one", version: 2), "one, replaced")

        expect { import(media_node(1, name: "one", version: 2)) }.not_to change(Media, :count)

        expect(stored_checksum(media)).to eq(image_checksum("one, replaced"))
        expect(media.shopify_info).to have_attributes(source_url: cdn_url("one", version: 2), checksum: image_checksum("one, replaced"))
      end

      it "keeps the row and downloads nothing for a node whose image is not ready" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"), alt: "Old", position: 3)
        blob_id = media.image.blob.id

        import(media_node(1, url: nil, alt: "New", position: 0))

        expect(media.reload).to have_attributes(alt: "New", position: 0)
        expect(media.shopify_info).to have_attributes(source_url: cdn_url("one"), checksum: image_checksum("one"))
        expect(media.image.blob.id).to eq(blob_id)
      end

      it "keeps a failed download's row and its old source_url so the next pull retries it" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one", version: 1), alt: "Old")
        stub_missing_cdn(cdn_url("one", version: 2))
        stub_cdn(cdn_url("two"), "two")

        import(media_node(1, name: "one", version: 2, alt: "New"), media_node(2, name: "two", position: 1))

        expect(media.reload.shopify_info.source_url).to eq(cdn_url("one", version: 1))
        expect(media.alt).to eq("Old")
        expect(product.media.count).to eq(2)
      end
    end

    context "when a node has no row with its Shopify ID" do
      it "creates a row for new media" do
        stub_cdn(cdn_url("new"), "new")

        expect { import(media_node(1, name: "new", alt: "Front", position: 2)) }.to change { product.media.count }.by(1)

        media = product.media.last
        expect(media).to have_attributes(alt: "Front", position: 2)
        expect(media.image).to be_attached
        expect(media.shopify_info).to have_attributes(
          store_id: media_gid(1),
          source_url: cdn_url("new"),
          checksum: image_checksum("new"),
          alt_text: "Front"
        )
      end

      it "creates nothing for a node whose image is not ready" do
        expect { import(media_node(1, url: nil)) }.not_to change(Media, :count)
      end

      it "ignores non-image nodes for creation, retention, and removal" do
        pulled_media("one", number: 1, source_url: cdn_url("one"))
        absent = pulled_media("two", number: 2, source_url: cdn_url("two"), position: 1)

        expect { import(media_node(1, name: "one"), non_image_node(1)) }.to change(Media, :count).by(-1)

        expect(Media.exists?(absent.id)).to be(false)
      end
    end

    context "when removing obsolete rows" do
      it "removes a row whose ID is absent from the payload even when nothing was downloaded" do
        kept = pulled_media("one", number: 1, source_url: cdn_url("one"))
        absent = pulled_media("two", number: 2, source_url: cdn_url("two"), position: 1)

        import(media_node(1, name: "one"))

        expect(Media.exists?(kept.id)).to be(true)
        expect(Media.exists?(absent.id)).to be(false)
      end

      it "removes a row without a Shopify ID whose bytes were not downloaded, even the twin of an unchanged row" do
        pulled_media("one", number: 1, source_url: cdn_url("one"))
        twin = pulled_media("one", position: 1)
        orphan = pulled_media("orphan", position: 2)

        import(media_node(1, name: "one"))

        expect(Media.where(id: [twin.id, orphan.id])).to be_empty
      end

      it "keeps a row without a Shopify ID when its bytes equal a download of this pull" do
        pulled_media("one", number: 1, source_url: cdn_url("one", version: 1))
        twin = pulled_media("one", position: 1)
        stub_cdn(cdn_url("one", version: 2), "one")

        import(media_node(1, name: "one", version: 2))

        expect(Media.exists?(twin.id)).to be(true)
      end

      it "links an absent-ID row to the node whose download has the same bytes instead of removing it" do
        pulled_media("one", number: 1, source_url: cdn_url("one"))
        moved = pulled_media("moved", number: 4, source_url: cdn_url("moved"), position: 1)
        stub_cdn(cdn_url("moved-again"), "moved")

        expect { import(media_node(1, name: "one"), media_node(5, name: "moved-again", position: 1)) }
          .not_to change(Media, :count)

        expect(moved.reload.shopify_info).to have_attributes(
          store_id: media_gid(5),
          source_url: cdn_url("moved-again"),
          checksum: image_checksum("moved")
        )
      end

      it "removes the absent-ID row and creates a row when the download has different bytes" do
        pulled_media("one", number: 1, source_url: cdn_url("one"))
        gone = pulled_media("gone", number: 4, source_url: cdn_url("gone"), position: 1)
        stub_cdn(cdn_url("fresh"), "fresh")

        import(media_node(1, name: "one"), media_node(5, name: "fresh", position: 1))

        expect(Media.exists?(gone.id)).to be(false)
        expect(product.media.reload.map { |media| media.shopify_info.store_id }).to contain_exactly(media_gid(1), media_gid(5))
      end

      it "removes nothing when every download failed" do
        failed = pulled_media("one", number: 1, source_url: cdn_url("one", version: 1))
        absent = pulled_media("two", number: 2, source_url: cdn_url("two"), position: 1)
        orphan = pulled_media("orphan", position: 2)
        stub_missing_cdn(cdn_url("one", version: 2))

        import(media_node(1, name: "one", version: 2))

        expect(Media.where(id: [failed.id, absent.id, orphan.id]).count).to eq(3)
      end

      it "removes nothing when the only new download failed" do
        pulled_media("two", number: 2, source_url: cdn_url("two"))
        orphan = pulled_media("orphan", position: 1)
        stub_missing_cdn(cdn_url("new"))

        expect { import(media_node(3, name: "new")) }.not_to change(Media, :count)
        expect(Media.exists?(orphan.id)).to be(true)
      end

      it "removes obsolete rows when only some downloads failed" do
        failed = pulled_media("one", number: 1, source_url: cdn_url("one", version: 1))
        absent = pulled_media("gone", number: 9, source_url: cdn_url("gone"), position: 1)
        stub_missing_cdn(cdn_url("one", version: 2))
        stub_cdn(cdn_url("two"), "two")

        import(media_node(1, name: "one", version: 2), media_node(2, name: "two", position: 1))

        expect(Media.exists?(failed.id)).to be(true)
        expect(Media.exists?(absent.id)).to be(false)
        expect(product.media.count).to eq(2)
      end

      it "links the loser of duplicate IDs to the node whose download has its bytes and removes nothing" do
        loser = pulled_media("c", position: 0)
        winner = pulled_media("a", position: 1)
        link_media(winner, 1)
        link_media(loser, 1)
        stub_cdn(cdn_url("c"), "c")

        expect { import(media_node(1, name: "a", position: 1), media_node(3, name: "c", position: 2)) }
          .not_to change(Media, :count)

        expect(a_request(:get, cdn_url("a"))).not_to have_been_made
        expect(winner.reload.shopify_info).to have_attributes(store_id: media_gid(1), source_url: cdn_url("a"))
        expect(loser.reload.shopify_info).to have_attributes(store_id: media_gid(3), source_url: cdn_url("c"))
      end

      it "removes the loser of duplicate IDs when the download has other bytes" do
        loser = pulled_media("c", position: 0)
        winner = pulled_media("a", position: 1)
        link_media(winner, 1)
        link_media(loser, 1)
        stub_cdn(cdn_url("c"), "other bytes")

        import(media_node(1, name: "a", position: 1), media_node(3, name: "c", position: 2))

        expect(Media.exists?(loser.id)).to be(false)
        expect(winner.reload.shopify_info).to have_attributes(store_id: media_gid(1), source_url: cdn_url("a"))
        expect(product.media.reload.size).to eq(2)
      end
    end

    it "closes the downloaded files" do
      stub_cdn(cdn_url("new"), "new")
      downloader = nil
      allow(Product::Shopify::Media::Downloader).to receive(:call).and_wrap_original do |original, **arguments|
        downloader = original.call(**arguments)
      end

      import(media_node(1, name: "new"))

      expect(downloader.downloads_by_key.values.map { |download| download.file.closed? }).to eq([true])
    end

    context "when pulling a product with new, changed, and unchanged images" do
      it "downloads only new or changed images and nothing on the next pull" do
        first = pulled_media("a", number: 1, source_url: nil)
        second = pulled_media("b", number: 2, source_url: cdn_url("b", version: 5), position: 1)
        stub_cdn(cdn_url("b", version: 9), "b, changed")
        stub_cdn(cdn_url("c"), "c")
        nodes = [
          media_node(1, name: "a"),
          media_node(2, name: "b", version: 9, position: 1),
          media_node(3, name: "c", position: 2)
        ]

        import(*nodes)

        expect(a_request(:get, cdn_url("a"))).not_to have_been_made
        expect(first.reload.shopify_info.source_url).to eq(cdn_url("a"))
        expect(stored_checksum(second)).to eq(image_checksum("b, changed"))
        expect(second.shopify_info.source_url).to eq(cdn_url("b", version: 9))
        expect(product.media.count).to eq(3)

        expect { import(*nodes) }.not_to change(Media, :count)
        expect(a_request(:get, cdn_url("b", version: 9))).to have_been_made.once
        expect(a_request(:get, cdn_url("c"))).to have_been_made.once
      end
    end

    context "when forced" do
      it "downloads every node with a URL even when nothing changed" do
        pulled_media("one", number: 1, source_url: cdn_url("one"))
        stub_cdn(cdn_url("one"), "one")

        import(media_node(1, name: "one"), force: true)

        expect(a_request(:get, cdn_url("one"))).to have_been_made.once
      end

      it "re-attaches a row whose file is missing from storage" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"))
        blob = media.image.blob
        blob.service.delete(blob.key)
        stub_cdn(cdn_url("one"), "one")

        import(media_node(1, name: "one"), force: true)

        replacement = media.reload.image.blob
        expect(replacement.id).not_to eq(blob.id)
        expect(replacement.service.exist?(replacement.key)).to be(true)
      end

      it "re-attaches a row whose download differs from its blob" do
        media = pulled_media("wrong image", number: 1, source_url: cdn_url("one"))
        stub_cdn(cdn_url("one"), "right image")

        import(media_node(1, name: "one"), force: true)

        expect(stored_checksum(media)).to eq(image_checksum("right image"))
        expect(media.shopify_info.checksum).to eq(image_checksum("right image"))
      end

      it "keeps the attachment when the file exists and the bytes are identical" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"))
        blob_id = media.image.blob.id
        stub_cdn(cdn_url("one"), "one")

        import(media_node(1, name: "one"), force: true)

        expect(media.reload.image.blob.id).to eq(blob_id)
      end

      it "makes no storage call when not forced" do
        changed = pulled_media("one", number: 1, source_url: cdn_url("one", version: 1))
        pulled_media("unchanged", number: 3, source_url: cdn_url("unchanged"), position: 2)
        service = changed.image.blob.service
        allow(service).to receive(:exist?).and_call_original
        stub_cdn(cdn_url("one", version: 2), "one")
        stub_cdn(cdn_url("new"), "new")

        import(
          media_node(1, name: "one", version: 2),
          media_node(2, name: "new", position: 1),
          media_node(3, name: "unchanged", position: 2)
        )

        expect(service).not_to have_received(:exist?)
      end
    end

    context "when counting queries" do
      it "runs the same queries for 2 and 20 unchanged images" do
        nodes = Array.new(20) { |index| media_node(index, name: "image-#{index}", position: index) }
        nodes.first(2).each_with_index do |node, index|
          pulled_media("bytes #{index}", number: index, source_url: node[:url], position: index)
        end
        two_images = count_queries { import(*nodes.first(2)) }

        nodes.drop(2).each_with_index do |node, offset|
          index = offset + 2
          pulled_media("bytes #{index}", number: index, source_url: node[:url], position: index)
        end
        twenty_images = count_queries { import(*nodes) }

        expect(twenty_images).to eq(two_images)
      end
    end
  end
end
