module Admin
  class SpeakersController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = Speaker.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   Speaker.find_by!(slug: param)
    # end

    def new
      # ensures that speaker is built for the current community (so scopes in administrate dashboards work)
      resource = current_community.speakers.new
      authorize_resource(resource)
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource),
      }
    end

    def create
      resource = resource_class.new(resource_params)
      # ensures speaker is created within the current community
      resource.community = current_community
      authorize_resource(resource)

      if resource.save
        redirect_to(
          [namespace, resource],
          notice: translate_with_resource("create.success"),
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource),
        }
      end
    end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    def import_csv
      if params[:file].nil?
        redirect_back(fallback_location: root_path)
        flash[:error] = "No file was attached!"
      else
        filepath = params[:file].read
        errors = Speaker.import_csv(filepath, current_community)
        errors.empty? ? flash[:notice] = "Speakers were imported successfully! View them #{view_context.link_to 'here', admin_speakers_path}." : flash[:error] = errors
        redirect_back(fallback_location: root_path)
      end
    end

    def default_sorting_attribute
      :name
    end

    def default_sorting_direction
      :asc
    end

    def import_page
      render "import_page"
    end

    def export_sample_csv
      send_data Speaker.export_sample_csv, filename: "sample_speakers.csv"
    end

    def delete
      remove_attachment
    end

    private

    def remove_attachment
      photo = ActiveStorage::Attachment.find(params[:attachment_id])
      photo.purge
      redirect_back(fallback_location: "/")
    end
  end
end
