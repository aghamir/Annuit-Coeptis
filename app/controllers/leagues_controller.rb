class LeaguesController < ApplicationController
  before_filter :authenticate_user!

  # implemented and partially tested
  def create
      @league = League.new(params[:league])
      @league.creator_id = current_user.id
      # attempt to save league so as to get its id
      if @league.save == true
        # Need to reload to get the league id back after the save
        @league.reload
        # Create the signed in user's portfolio as a league manager
        @portfolio = create_manager_portfolio(@league)
        if @portfolio.save
          day_performance = Performance.new();
          day_performance.portfolio_id = @portfolio.id;
          day_performance.league_id = @league.id;
          day_performance.date = Date.today;
          day_performance.closing_capital_cents = @portfolio.capital_cents;
          day_performance.save();
          # Flash a success message
          flash[:success] = "Created your league!"
          # Send them to the league
          redirect_to @league
        else
          logger.info("Portfolio creation failed.")
          @league.delete
          flash[:fail] = "Sorry, portfolio couldn't be created."
          render 'new'
        end
      else
        logger.info(@league.errors.full_messages)
        logger.info("League creation failed.")
        flash[:fail] = @league.errors.full_messages;
        render 'new'
      end
  end

  # implemented and partially tested
  def index
    #Get an array of all leagues
    @leags = League.all
    
    #Set a variable to false for later
    @filtered = false

    #If we are filtering, we want to go in here
    if params[:filter] != nil
      #Lessen the array we had according to the filter set
      @leags = League.where("name LIKE ?", "%"+params[:filter]+"%")

      #Set the variable from before to true so we know that we did infact filter.
      @filtered = true
    end

    #Save this for later just incase we want to paginate with different pages
    @leagues = League.where(:private => false).paginate(:page => params[:page])
  end

  # not implemented
  def destroy
    
    league = League.find_by_id(params[:id])
    performances = Performance.where(:league_id => league.id)
    comments = Comment.where(:location_id => league.id)
    for comment in comments
      if comment.comment_type == 1   
        comment.delete
      end
    end
    for performance in performances
      performance.delete
    end
    portfolios = Portfolio.where(:league_id => league.id)
    for portfolio in portfolios
      portfolio.delete
    end
    #Get the portfolio we want to remove

    #Find out if it has already been removed (If someone presses it twice)
    if league != nil
      #If not, delete it
      league.delete
    end
    

    #Go back to the league page
    redirect_to leagues_url
  end

  # implemented and partially tested
  def show
      if flash[:focus] == true
        @focus = true
      end
     @league = League.find(params[:id])
     @title = @league.name   

     # List of portfolios to render
     @portfolios = Portfolio.where(:league_id=>@league.id).paginate(:page=>params[:page], :per_page=>10)
     @performances = Performance.where(:league_id=>@league.id)   
     @sortedPort = []
     for portfolio in @portfolios
       rank = League.find_rank(portfolio.id, portfolio.league_id)
       @sortedPort.append([portfolio.id,rank])
     end

      # Create a local portfolio if user isn't in league and decides to join
     @portfolio = Portfolio.where("user_id = ? AND league_id = ?",current_user.id, @league.id).first
     @portfolio = @league.portfolios.build if @portfolio.nil?
    
  end

  # not implemented
  def edit
     @league = League.find(params[:id])
     @title = "League settings" 
  end
  def update
   @league = League.find(params[:id])
   if @league.update_attributes(params[:league])
     redirect_to :back
   end
  end

  # implemented, shouldn't need to be tested...
  def new
    @league = League.new
  end

  private

  # implemented and tested
  def create_manager_portfolio(league)
    @portfolio = Portfolio.new(:capital => league.capital, :user_id => current_user.id,
                               :margin => league.capital, :manager => true,
                                :league_id => league.id)
  end
end
