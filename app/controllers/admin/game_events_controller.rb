class Admin::GameEventsController < Admin::BaseController
  before_action :set_game_event, only: [ :show, :edit, :update, :destroy ]

  def index
    @game_events = GameEvent.includes(:user).order(occurred_at: :desc)
    @game_events = @game_events.where(game_name: params[:game_name]) if params[:game_name].present?
    @game_events = @game_events.where(user_id: params[:user_id]) if params[:user_id].present?
    @game_events = @game_events.page(params[:page]).per(20)

    # Available filters
    @available_games = GameEvent.distinct.pluck(:game_name)
    @available_users = User.order(:email)
  end

  def show
    # Navigation data
    @prev_event = GameEvent.where("id < ?", @game_event.id).order(id: :desc).first
    @next_event = GameEvent.where("id > ?", @game_event.id).order(:id).first
  end

  def new
    @game_event = GameEvent.new
    @users = User.order(:email)
    @available_games = [
      "Brevity", "Wordbend", "Retention", "Focus", "Name Recall",
      "Writing", "Vocabulary", "Speaking", "Reading", "Memory", "Math", "Concentration"
    ]
  end

  def create
    @game_event = GameEvent.new(game_event_params)
    @users = User.order(:email)
    @available_games = [
      "Brevity", "Wordbend", "Retention", "Focus", "Name Recall",
      "Writing", "Vocabulary", "Speaking", "Reading", "Memory", "Math", "Concentration"
    ]

    if @game_event.save
      Logging::AdminActivityLoggerService.log_activity(
        current_admin_user,
        "create",
        "game_event",
        @game_event.id,
        { game_name: @game_event.game_name, user_email: @game_event.user.email }
      )
      redirect_to admin_game_event_path(@game_event)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.order(:email)
    @available_games = [
      "Brevity", "Wordbend", "Retention", "Focus", "Name Recall",
      "Writing", "Vocabulary", "Speaking", "Reading", "Memory", "Math", "Concentration"
    ]
  end

  def update
    # Check if this is actually a delete request
    if params[:commit] == "Delete"
      event_details = { game_name: @game_event.game_name, user_email: @game_event.user.email }
      @game_event.destroy
      Logging::AdminActivityLoggerService.log_activity(
        current_admin_user,
        "delete",
        "game_event",
        @game_event.id,
        event_details.merge(method: "update_form")
      )
      redirect_to admin_game_events_path
    else
      @users = User.order(:email)
      @available_games = [
        "Brevity", "Wordbend", "Retention", "Focus", "Name Recall",
        "Writing", "Vocabulary", "Speaking", "Reading", "Memory", "Math", "Concentration"
      ]

      if @game_event.update(game_event_params)
        Logging::AdminActivityLoggerService.log_activity(
          current_admin_user,
          "update",
          "game_event",
          @game_event.id,
          { game_name: @game_event.game_name, user_email: @game_event.user.email }
        )
        redirect_to admin_game_event_path(@game_event)
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    event_details = { game_name: @game_event.game_name, user_email: @game_event.user.email }
    @game_event.destroy
    Logging::AdminActivityLoggerService.log_activity(
      current_admin_user,
      "delete",
      "game_event",
      @game_event.id,
      event_details.merge(method: "destroy_action")
    )
    redirect_to admin_game_events_path
  end

  private

  def set_game_event
    @game_event = GameEvent.find_by(id: params[:id])
    unless @game_event
      redirect_to admin_game_events_path(error: "Game event with ID #{params[:id]} does not exist")
      nil
    end
  end

  def game_event_params
    params.require(:game_event).permit(:user_id, :game_name, :event_type, :occurred_at)
  end
end
