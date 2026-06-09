# frozen_string_literal: true

class MediaUploadsController < ApplicationController
  def create
    file = params[:file]
    return render json: {error: "No file"}, status: :unprocessable_content if file.blank?

    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )

    render json: {signed_id: blob.signed_id}
  end
end
