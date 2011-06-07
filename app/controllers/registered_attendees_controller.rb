class RegisteredAttendeesController < InheritedResources::Base
  defaults :resource_class => Attendee, :collection_name => "attendees", :instance_name => "attendee"
  actions :index, :show, :update
  
  def update
    params[:attendee][:status_event] = 'confirm' if params[:attendee]
    update! do |success, failure|
      success.html do
        flash[:notice] = t('flash.registered_attendees.confirm.success')
        redirect_to registered_attendees_path
      end
      failure.html do
        flash.now[:error] = t('flash.failure')
        render :show
      end
    end
  end  
  
  private
  def collection
    direction = params[:direction] == 'up' ? 'ASC' : 'DESC'
    column = sanitize(params[:column].presence || 'registration_date')
    order = "#{column} #{direction}"
    
    paginate_options ||= {}
    paginate_options[:page] ||= (params[:page] || 1)
    paginate_options[:per_page] ||= (params[:per_page] || 30)
    paginate_options[:order] ||= order
    
    scope = end_of_association_chain.for_conference(current_conference).with_full_name
    scope = scope.search(params[:q]) if params[:q].present?
    scope = scope.with_status(params[:status].to_sym) if params[:status].present?
    
    @attendees ||= scope.paginate(paginate_options)
  end
  
end