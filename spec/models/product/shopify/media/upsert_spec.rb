# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Upsert do
  include Helpers::QueryCounter
  include Helpers::ShopifyMediaScenarios

  let(:product) { create(:product) }
  let(:tempfiles) { [] }

  after { tempfiles.each(&:close!) }

  def download(bytes)
    file = Tempfile.new(["download", ".jpg"])
    file.write(bytes)
    file.rewind
    tempfiles << file
    Product::Shopify::Media::Downloader::DownloadedImage.new(file:, filename: "download.jpg", checksum: image_checksum(bytes))
  end

  def upsert_for(*nodes, force: false)
    described_class.new(product:, media_items: nodes, force:)
  end

  def pull(*nodes, downloads: {}, force: false)
    upsert_for(*nodes, force:).call(downloads_by_key: downloads.transform_keys { |number| media_gid(number) })
  end

  describe "#media_items_to_download" do
    it "includes a row that has no attached image even when its URL is unchanged" do
      media = pulled_media("one", number: 1, source_url: cdn_url("one"))
      media.image.detach

      expect(upsert_for(media_node(1, name: "one")).media_items_to_download.pluck(:id)).to eq([media_gid(1)])
    end

    it "leaves out nodes without an image URL" do
      pulled_media("one", number: 1, source_url: cdn_url("one"))

      expect(upsert_for(media_node(1, url: nil), non_image_node(1)).media_items_to_download).to be_empty
    end
  end

  describe "#call" do
    context "when a row matches by Shopify ID and its source_url equals the URL" do
      it "updates alt and position when they differ" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"), alt: "Old", position: 4)

        pull(media_node(1, name: "one", alt: "New", position: 0))

        expect(media.reload).to have_attributes(alt: "New", position: 0)
        expect(media.shopify_info).to have_attributes(alt_text: "New", source_url: cdn_url("one"))
      end

      it "writes only pull_time, in one statement, for rows with nothing to change" do
        rows = Array.new(3) { |index| pulled_media("bytes #{index}", number: index, source_url: cdn_url(index), alt: "Alt", position: index) }
        nodes = rows.each_index.map { |index| media_node(index, alt: "Alt", position: index) }
        updated_ats = rows.map { |media| media.reload.updated_at }
        previous_pull_times = rows.map { |media| media.shopify_info.pull_time }

        queries = capture_queries { pull(*nodes) }

        expect(queries.grep(/UPDATE "media"/)).to be_empty
        expect(queries.grep(/UPDATE "store_infos"/).size).to eq(1)
        expect(rows.map { |media| media.reload.updated_at }).to eq(updated_ats)
        expect(rows.map { |media| media.shopify_info.pull_time }).to all(be > previous_pull_times.max)
      end

      it "does not touch the attachment or checksum" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"))
        blob_id = media.image.blob.id

        pull(media_node(1, name: "one"))

        expect(media.reload.image.blob.id).to eq(blob_id)
        expect(media.shopify_info.checksum).to eq(image_checksum("one"))
      end
    end

    context "when a row matches by Shopify ID and has no source_url" do
      it "stores the URL and alt text and leaves the bytes and checksum alone" do
        media = pulled_media("one", number: 1, source_url: nil, alt: "Alt", alt_text: nil)
        blob_id = media.image.blob.id

        pull(media_node(1, name: "one", alt: "Alt"))

        expect(media.reload.shopify_info).to have_attributes(source_url: cdn_url("one"), alt_text: "Alt", checksum: image_checksum("one"))
        expect(media.image.blob.id).to eq(blob_id)
      end

      it "writes nothing to the media row when alt and position are unchanged" do
        pulled_media("one", number: 1, source_url: nil, alt: "Alt", position: 2, alt_text: nil)

        queries = capture_queries { pull(media_node(1, name: "one", alt: "Alt", position: 2)) }

        expect(queries.grep(/UPDATE "media"/)).to be_empty
      end
    end

    context "when a row matches by Shopify ID and its source_url differs from the URL" do
      let!(:media) { pulled_media("one", number: 1, source_url: cdn_url("one", version: 1), position: 2) }
      let(:node) { media_node(1, name: "one", version: 2, alt: "New", position: 0) }

      it "replaces the attachment on the same row when the bytes differ" do
        previous_blob = media.image.blob

        expect { pull(node, downloads: {1 => download("one, replaced")}) }
          .to have_enqueued_job(ActiveStorage::PurgeJob)

        expect(product.media.reload.map(&:id)).to eq([media.id])
        expect(media.reload.image.blob.id).not_to eq(previous_blob.id)
        expect(media.image.blob.checksum).to eq(image_checksum("one, replaced"))
        expect(media).to have_attributes(alt: "New", position: 0)
        expect(media.shopify_info).to have_attributes(
          source_url: cdn_url("one", version: 2),
          checksum: image_checksum("one, replaced"),
          alt_text: "New"
        )
      end

      it "keeps the attachment when the bytes are identical and still stores the URL and checksum" do
        blob_id = media.image.blob.id
        media.shopify_info.update!(checksum: "stale")

        pull(node, downloads: {1 => download("one")})

        expect(media.reload.image.blob.id).to eq(blob_id)
        expect(media.shopify_info).to have_attributes(source_url: cdn_url("one", version: 2), checksum: image_checksum("one"))
      end

      it "leaves the row untouched when its download failed" do
        pull(node)

        expect(media.reload).to have_attributes(alt: "", position: 2)
        expect(media.shopify_info).to have_attributes(source_url: cdn_url("one", version: 1), checksum: image_checksum("one"))
      end
    end

    context "when a row matches by Shopify ID and has no attached image" do
      it "attaches the download and stores the URL and checksum" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"))
        media.image.detach

        pull(media_node(1, name: "one"), downloads: {1 => download("one")})

        expect(media.reload.image).to be_attached
        expect(media.image.blob.checksum).to eq(image_checksum("one"))
      end
    end

    context "when the node's image is not ready" do
      it "keeps the row, updates alt and position, and writes no URL, checksum, or attachment" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"), alt: "Old", position: 3)
        blob_id = media.image.blob.id

        pull(media_node(1, url: nil, alt: "New", position: 0))

        expect(media.reload).to have_attributes(alt: "New", position: 0)
        expect(media.shopify_info).to have_attributes(source_url: cdn_url("one"), checksum: image_checksum("one"), alt_text: "New")
        expect(media.image.blob.id).to eq(blob_id)
      end

      it "creates nothing when no row has its ID" do
        expect { pull(media_node(1, url: nil)) }.not_to change(Media, :count)
      end
    end

    context "when several rows share one Shopify ID" do
      let!(:loser) { pulled_media("c", position: 0) }
      let!(:winner) { pulled_media("a", position: 1) }
      let(:nodes) { [media_node(1, name: "a"), media_node(3, name: "c", position: 1)] }

      before do
        link_media(winner, 1)
        link_media(loser, 1)
      end

      it "keeps the ID on the row with the lowest store info id and links the other by checksum" do
        expect { pull(*nodes, downloads: {3 => download("c")}) }.not_to change(Media, :count)

        expect(winner.reload.shopify_info).to have_attributes(store_id: media_gid(1), source_url: cdn_url("a"))
        expect(loser.reload.shopify_info).to have_attributes(
          store_id: media_gid(3),
          source_url: cdn_url("c"),
          checksum: image_checksum("c")
        )
      end

      it "strips the other row's Shopify info and creates a row when no download has its bytes" do
        expect { pull(*nodes, downloads: {3 => download("other")}) }.to change(Media, :count).by(1)

        expect(winner.reload.shopify_info.store_id).to eq(media_gid(1))
        expect(loser.reload.shopify_info).to be_nil
        expect(product.media.reload.map { |media| media.shopify_info&.store_id }).to contain_exactly(media_gid(1), nil, media_gid(3))
      end
    end

    context "when no row has the node's Shopify ID" do
      it "links a row without a Shopify ID whose bytes equal the download" do
        media = pulled_media("one", alt: "Old", position: 2)

        expect { pull(media_node(5, name: "one", alt: "New", position: 0), downloads: {5 => download("one")}) }
          .not_to change(Media, :count)

        expect(media.reload).to have_attributes(alt: "New", position: 0)
        expect(media.shopify_info).to have_attributes(
          store_id: media_gid(5),
          source_url: cdn_url("one"),
          checksum: image_checksum("one"),
          alt_text: "New"
        )
      end

      it "moves the stale ID of a row that is absent from the payload onto the node" do
        media = pulled_media("one", number: 4, source_url: cdn_url("old"))

        expect { pull(media_node(5, name: "one"), downloads: {5 => download("one")}) }.not_to change(Media, :count)

        expect(media.reload.shopify_info).to have_attributes(store_id: media_gid(5), source_url: cdn_url("one"))
      end

      it "links one row per node and creates a row for the next node with the same bytes" do
        media = pulled_media("one")

        expect {
          pull(media_node(5, name: "first"), media_node(6, name: "second", position: 1), downloads: {5 => download("one"), 6 => download("one")})
        }.to change(Media, :count).by(1)

        expect(media.reload.shopify_info.store_id).to eq(media_gid(5))
        expect(product.media.reload.map { |row| row.shopify_info.store_id }).to contain_exactly(media_gid(5), media_gid(6))
      end

      it "does not link a row whose ID is in the payload" do
        pulled_media("one", number: 1, source_url: cdn_url("one"))

        expect { pull(media_node(1, name: "one"), media_node(2, name: "twin", position: 1), downloads: {2 => download("one")}) }
          .to change(Media, :count).by(1)
      end

      it "creates a row for new media" do
        expect { pull(media_node(7, name: "new", alt: "Front", position: 2), downloads: {7 => download("new")}) }
          .to change(Media, :count).by(1)

        media = product.media.last
        expect(media).to have_attributes(alt: "Front", position: 2)
        expect(media.image).to be_attached
        expect(media.image.blob.checksum).to eq(image_checksum("new"))
        expect(media.shopify_info).to have_attributes(
          store_id: media_gid(7),
          source_url: cdn_url("new"),
          checksum: image_checksum("new"),
          alt_text: "Front"
        )
        expect(media.shopify_info.pull_time).to be_within(1.minute).of(Time.current)
      end

      it "creates nothing when the download failed" do
        expect { pull(media_node(7, name: "new")) }.not_to change(Media, :count)
      end

      it "ignores non-image nodes" do
        expect { pull(non_image_node(0), media_node(7, name: "new", position: 1), downloads: {7 => download("new")}) }
          .to change(Media, :count).by(1)
        expect(product.media.last.position).to eq(1)
      end
    end

    context "when two Shopify IDs serve identical bytes" do
      let(:nodes) { [media_node(1, name: "front"), media_node(2, name: "back", position: 1)] }

      it "keeps two rows across repeated pulls" do
        pull(*nodes, downloads: {1 => download("same"), 2 => download("same")})
        expect(product.media.reload.size).to eq(2)

        pull(*nodes)
        expect(product.media.reload.size).to eq(2)

        pull(*nodes, downloads: {1 => download("same"), 2 => download("same")}, force: true)
        expect(product.media.reload.size).to eq(2)
        expect(product.media.map { |media| media.shopify_info.store_id }).to contain_exactly(media_gid(1), media_gid(2))
      end
    end

    context "when forced" do
      it "re-attaches a row whose file is missing from storage" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"))
        blob = media.image.blob
        blob.service.delete(blob.key)

        pull(media_node(1, name: "one"), downloads: {1 => download("one")}, force: true)

        replacement = media.reload.image.blob
        expect(replacement.id).not_to eq(blob.id)
        expect(replacement.service.exist?(replacement.key)).to be(true)
      end

      it "re-attaches a linked row whose file is missing from storage" do
        media = pulled_media("one")
        blob = media.image.blob
        blob.service.delete(blob.key)

        pull(media_node(5, name: "one"), downloads: {5 => download("one")}, force: true)

        expect(media.reload.image.blob.id).not_to eq(blob.id)
        expect(media.shopify_info.store_id).to eq(media_gid(5))
      end

      it "re-attaches a row whose download differs from its blob" do
        media = pulled_media("wrong image", number: 1, source_url: cdn_url("one"))

        pull(media_node(1, name: "one"), downloads: {1 => download("right image")}, force: true)

        expect(media.reload.image.blob.checksum).to eq(image_checksum("right image"))
        expect(media.shopify_info.checksum).to eq(image_checksum("right image"))
      end

      it "keeps the attachment when the file exists and the bytes are identical" do
        media = pulled_media("one", number: 1, source_url: cdn_url("one"))
        blob_id = media.image.blob.id

        pull(media_node(1, name: "one"), downloads: {1 => download("one")}, force: true)

        expect(media.reload.image.blob.id).to eq(blob_id)
      end
    end

    context "when not forced" do
      it "makes no storage call for changed, linked, or new media" do
        changed = pulled_media("one", number: 1, source_url: cdn_url("one", version: 1))
        pulled_media("two", position: 1)
        service = changed.image.blob.service
        allow(service).to receive(:exist?).and_call_original

        pull(
          media_node(1, name: "one", version: 2),
          media_node(2, name: "two", position: 1),
          media_node(3, name: "three", position: 2),
          downloads: {1 => download("one"), 2 => download("two"), 3 => download("three")}
        )

        expect(service).not_to have_received(:exist?)
      end
    end
  end
end
